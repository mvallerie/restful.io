toSource = require 'tosource'
_ = require 'underscore'

Route = require './route'
SessionManager = require('./session/SessionManager')

ss = require 'socket.io-stream'

module.exports = class RestfulRouter

  constructor: (@ctx, @routes, @verbose = false, @methodSeparator = ':', @uriSeparator = '/', @parameterPrefix = 'p:', @resultSuffix = 'RESULT') ->

  log: (str) ->
    console.log "[LOG] RestfulRouter: #{str}"

  start: (io, beforeRouting = undefined) =>
    @log "Router started"


    @sessionManager = new SessionManager()
    @bindPublicAPI()

    io.on "connection", (socket) =>
      beforeRouting?(socket)
      @log "New client connected"
      @bindRoutes(@routes, socket)


  # TODO All the following needs some functional refactoring
  bindPublicAPI: () =>
    API = @getPublicAPI(@routes)
    SrcAPI = (API) ->
      """(function() {
        return function(socket, ss, verbose) {
          var API = #{toSource(API)};
          API.socket = socket;
          API.ss = ss;
          API.token = "";
          API.verbose = (verbose === true);
          API.log = function(str) {
            if(API.verbose) {
              console.log("[API] " + str);
            }
          };
          return API;
        };
      })()"""


    if !@routes.GET? then @routes.GET = []

    if not @ctx["APIController"]?
      @ctx["APIController"] = {}
    getHook = @ctx["APIController"].get
    @ctx["APIController"].get = (route) ->
      route.OK(SrcAPI(if getHook? then getHook(API) else API))

    apiRoute = {uri: "/api", to: "APIController.get()", public: true}
    @routes.GET.push(apiRoute)

  getPublicAPI: (routes, nestedIn = undefined) =>
    result = {_stream: false}

    result.stream = (stream) ->
      newAPI = {}
      # Here, we "clone" the API
      for k,v of API
        newAPI[k] = v
      if typeof(File) is "function" and stream instanceof File
        newAPI._stream = newAPI.ss.createBlobReadStream(stream).pipe(newAPI.ss.createStream())
      else
        # We assume it's a regular stream
        newAPI._stream = stream.pipe(newAPI.ss.createStream())
      newAPI



    for method, methodData of routes
      absmethod = if nestedIn? then "#{nestedIn}#{@methodSeparator}#{method}" else method
      if Array.isArray(methodData)
        # TODO Templating ?
        # Here, "socket" variable will be provided by context when API will be evaled on client
        result[method] = eval("""(function() {
            return function(uri, json, callback) {
              var params = {
                requestId: new Date().getTime(), json: json, token: API.token
              };

              if(callback != undefined) {
                var logWrapper = function(stream) {
                  return function(data) {
                    API.log('Response from ' + uri + ' : ');
                    API.log(JSON.stringify(data));
                    callback(data, stream);
                  };
                };
                if(callback.length == 2)
                  ss(socket).on('#{absmethod}#{@methodSeparator}'+params.requestId, function(stream, data) { logWrapper(stream)(data); });
                else
                  socket.on('#{absmethod}#{@methodSeparator}'+params.requestId, logWrapper());
              }

              API.log('Sending #{absmethod} on ' + uri + ' with params:');
              API.log(JSON.stringify(params));
              if(this._stream) {
                ss(socket).emit('#{absmethod}#{@methodSeparator}'+uri, this._stream, params);
              }
              else {
                socket.emit('#{absmethod}#{@methodSeparator}'+uri, params);
              }
            };
          })()""");
      else if typeof methodData == "object"
        result[method] = @getPublicAPI(methodData, absmethod)

    result._stream = false

    result


  bindRoutes: (routes, socket, nestedIn = undefined) =>
    for method, methodData of routes
      if Array.isArray(methodData)
        @bindMethod socket, method, methodData
      else if typeof methodData == "object"
        @bindRoutes methodData, socket, if nestedIn? then "#{nestedIn}#{@methodSeparator}#{method}" else method

  # TODO bind wildcard to 404
  bindMethod: (socket, methodName, methodData) ->
    @log "Binding #{methodName}"
    for route in methodData
      do (route) =>
        routeEvent = "#{methodName}#{@methodSeparator}#{route.uri}"
        @log "  #{route.uri}"

        routeCallback = (data, stream = undefined) =>
          json = if data? then data.json else {}
          @log "Received request #{methodName} #{route.uri}"

          routeHandler = route.to
          requestId = if data?.requestId? then data.requestId else @resultSuffix

          r = new Route(@ctx, methodName, route.uri, route.public, stream, routeHandler, json, @parameterPrefix, (result, stream = undefined) =>
            if stream?
              ss(socket).emit "#{methodName}#{@methodSeparator}#{requestId}", stream, result
            else
              socket.emit "#{methodName}#{@methodSeparator}#{requestId}", result
          , @verbose)

          @sessionManager.handleRequest r, data?.token

        if route.stream == true
          ss(socket).on routeEvent, (stream, data) ->
            routeCallback(data, stream)
        else
          socket.on routeEvent, (data) -> routeCallback(data)


    #@log "No route found for #{methodName} #{uri}"
