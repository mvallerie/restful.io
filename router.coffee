toSource = require 'tosource'

module.exports = class RestfulRouter

  constructor: (@ctx, @routes, @verbose = false, @methodSeparator = ':', @uriSeparator = '/', @parameterPrefix = 'p:', @jsonParameterPrefix = 'j:', @resultSuffix = 'RESULT') ->

  log: (str) ->
    console.log "[LOG] RestfulRouter: #{str}"

  start: (io, publicAPI = false, beforeRouting = undefined) =>
    @log "Router started"
    if publicAPI then @bindPublicAPI()
    io.on "connection", (socket) =>
      beforeRouting?(socket)
      if @verbose then @log "New client connected"
      @bindRoutes(@routes, socket)


  # TODO All the following needs some functional refactoring
  bindPublicAPI: () =>
    API = @getPublicAPI(@routes)
    SrcAPI = (API) ->
      """(function() {
        return function(socket) {
          var API = #{toSource(API)};
          API.socket = socket;
          API.requestId = 0;
          return API;
        };
      })()"""

    if @ctx["APIController"]?
      customGet = @ctx["APIController"].get
      @ctx["APIController"].get = () -> SrcAPI(if customGet? then customGet(API) else API)
    else
      @ctx["APIController"] = {
        get: () -> SrcAPI(API)
      }

    route = {uri: "/api", to: "APIController.get()"}
    if !@routes.GET? then @routes.GET = [route] else @routes.GET.push(route)


  getPublicAPI: (routes, nestedIn = undefined) =>
    result = {}
    for method, methodData of routes
      absmethod = if nestedIn? then "#{nestedIn}#{@methodSeparator}#{method}" else method
      if Array.isArray(methodData)
        # Here, "socket" variable will be provided by context when API will be evaled on client
        result[method] = eval("""(function() {
            return function(uri, json, callback) {
              this.requestId = this.requestId + 1;
              params = {requestId: this.requestId, uri: uri, json: json};
              socket.on('#{absmethod}:'+this.requestId, callback);
              socket.emit('#{absmethod}', params);
            };
          })()""");
      else if typeof methodData == "object"
        result[method] = @getPublicAPI(methodData, absmethod)
    result


  bindRoutes: (routes, socket, nestedIn = undefined) =>
    for method, methodData of routes
      if Array.isArray(methodData)
        @bindMethod socket, method, methodData
      else if typeof methodData == "object"
        @bindRoutes methodData, socket, if nestedIn? then "#{nestedIn}#{@methodSeparator}#{method}" else method

  bindMethod: (socket, methodName, methodData) ->
    if @verbose then @log "Binding #{methodName}"
    socket.on methodName, (data) =>
      uri = if typeof data == "string" then data else data.uri
      json = if typeof data == "string" then {} else data.json

      if @verbose then @log "Received request #{methodName} #{uri}"
      for route in methodData
        params = @matchURI(uri, json, route.uri)
        if params
          routeHandler = route.to
          if @verbose then @log "Calling #{routeHandler} for #{methodName} #{uri}"
          requestId = if data.requestId? then data.requestId else @resultSuffix
          socket.emit "#{methodName}#{@methodSeparator}#{requestId}", @evalRouteHandler(routeHandler, params)
          return
      if @verbose then @log "No route found for #{methodName} #{uri}"

  # TODO Needs regexp and / or good parsing method
  matchURI: (uri, jsonParams, pattern) =>
    segmentedURI = uri.split(@uriSeparator)
    segmentedPattern = pattern.split(@uriSeparator)
    if segmentedURI.length != segmentedPattern.length
      false
    else
      params = {}
      for i in [0..segmentedPattern.length-1]
        if segmentedPattern[i] != ""
          if segmentedPattern[i].indexOf(@jsonParameterPrefix) == 0
            pname = segmentedURI[i].substr(@jsonParameterPrefix.length)
            params[segmentedPattern[i].substr(@jsonParameterPrefix.length)] = jsonParams[pname]
          else if segmentedPattern[i].indexOf(@parameterPrefix) == 0
            params[segmentedPattern[i].substr(@parameterPrefix.length)] = segmentedURI[i]
          else if segmentedPattern[i] != segmentedURI[i]
            # Explicit return breaks the function
            return false
      params

  getMethodName: (routeHandler) ->


  # TODO REALLY needs REGEXP...quick and dirty work
  evalRouteHandler: (routeHandler, params) ->
    startCS = routeHandler.indexOf('.')
    endCS = routeHandler.indexOf('(')
    endArgs = routeHandler.lastIndexOf(')')

    handlerObj = @ctx[routeHandler.substr(0, startCS)]
    callstack = routeHandler.substr(startCS+1, endCS-startCS-1)
    args = routeHandler.substr(endCS+1, endArgs-(endCS+1))
    handlerMethod = handlerObj

    for call in callstack.split('.')
      handlerMethod = handlerMethod?[call]

    paramStack = [];
    for arg in args.split(',')
      paramStack.push(params[arg])

    handlerMethod?.apply(handlerMethod, paramStack)
