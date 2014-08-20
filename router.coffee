toSource = require 'tosource'

Route = require './route'
handlers =
  TokenAuthHandler: require './auth/TokenAuthHandler'
  UserGroupAuthHandler: require './auth/UserGroupAuthHandler'


module.exports = class RestfulRouter

  constructor: (@ctx, @routes, @verbose = false, @methodSeparator = ':', @uriSeparator = '/', @parameterPrefix = 'p:', @jsonParameterPrefix = 'j:', @resultSuffix = 'RESULT') ->

  log: (str) ->
    console.log "[LOG] RestfulRouter: #{str}"

  start: (io, publicAPI = false, beforeRouting = undefined) =>
    @log "Router started"

    if publicAPI != false
      if typeof publicAPI == "object" then @authHandler = publicAPI
      else @authHandler = new handlers.TokenAuthHandler()
      @authHandler.handleRoutes(@routes)
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
        return function(socket, verbose) {
          var API = #{toSource(API)};
          API.socket = socket;
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

    defaultLoginImpl = (authHandler) -> (route, authData) ->
      authHandler.login route, authData

    defaultLogoutImpl = (authHandler) -> (route) ->
      authHandler.logout route


    if @ctx["APIController"]?
      getHook = @ctx["APIController"].get
      @ctx["APIController"].get = (route) ->
        route.OK(SrcAPI(if getHook? then getHook(API) else API))

      # TODO disable auth hooks for now. Need to think about it.
      if @authHandler?
        #loginHook = @ctx["APIController"].login
        #if not loginHook?
          @ctx["APIController"].login = defaultLoginImpl(@authHandler)
        #else
        #  @ctx["APIController"].login = (route, authdata) =>
        #    loginHook(route, authdata, @authHandler)


        #logoutHook = @ctx["APIController"].logout
        #if not logoutHook?
          @ctx["APIController"].logout = defaultLogoutImpl(@authHandler)
        #else
        #  @ctx["APIController"].logout = (route) =>
        #    logoutHook(route, @authHandler)
    else
      @ctx["APIController"] = {
        get: (route) -> route.OK(SrcAPI(API))

        login: (if @authHandler? then defaultLoginImpl(@authHandler) else undefined)

        logout: (if @authHandler? then defaultLogoutImpl(@authHandler) else undefined)
      }

    apiRoute = {uri: "/api", to: "APIController.get()", public: true}
    @routes.GET.push(apiRoute)

    if @authHandler?
      loginRoute = {uri: "/api/login", to: "APIController.login(j:auth)", public: true}
      logoutRoute = {uri: "/api/logout", to: "APIController.logout()"}
      @routes.GET.push(loginRoute, logoutRoute)


  getPublicAPI: (routes, nestedIn = undefined) =>
    result = {requestId: 0}

    for method, methodData of routes
      absmethod = if nestedIn? then "#{nestedIn}#{@methodSeparator}#{method}" else method
      if Array.isArray(methodData)
        # TODO Templating ?
        # Here, "socket" and "requestId" variables will be provided by context when API will be evaled on client
        result[method] = eval("""(function() {
            return function(uri, json, callback) {
              this.requestId = this.requestId + 1;
              var params = {
                requestId: this.requestId, uri: uri, json: json #{if @authHandler? then ", token: API.token"}
              };

              if(callback != undefined) API.socket.on('#{absmethod}:'+this.requestId, function(data) {
                API.log('Response from ' + uri + ' : ');
                API.log(JSON.stringify(data));
                callback(data);
              })

              API.log('Sending #{absmethod} on ' + uri + ' with params:');
              API.log(JSON.stringify(params));
              socket.emit('#{absmethod}', params);
            };
          })()""");
      else if typeof methodData == "object"
        result[method] = @getPublicAPI(methodData, absmethod)

    result.requestId = 0

    result


  bindRoutes: (routes, socket, nestedIn = undefined) =>
    for method, methodData of routes
      if Array.isArray(methodData)
        @bindMethod socket, method, methodData
      else if typeof methodData == "object"
        @bindRoutes methodData, socket, if nestedIn? then "#{nestedIn}#{@methodSeparator}#{method}" else method

  bindMethod: (socket, methodName, methodData) ->
    @log "Binding #{methodName}"
    socket.on methodName, (data) =>
      uri = if typeof data == "string" then data else data.uri
      json = if typeof data == "string" then {} else data.json

      @log "Received request #{methodName} #{uri}"
      for route in methodData
        params = @matchURI(uri, route.uri)
        if params != false
          routeHandler = route.to
          requestId = if data.requestId? then data.requestId else @resultSuffix

          r = new Route(@ctx, methodName, route.uri, routeHandler, params, json, @jsonParameterPrefix, (result) =>
            socket.emit "#{methodName}#{@methodSeparator}#{requestId}", result
          , @verbose)
          if @authHandler?
            if data.token? && data.token != "" then r.token = data.token
            if route.public != true
              @authHandler.handleRequest r, params
            else
              r.follow()
          else
            r.follow()

          return


      @log "No route found for #{methodName} #{uri}"

  # TODO Needs regexp and / or good parsing method
  matchURI: (uri, pattern) =>
    segmentedURI = uri.split(@uriSeparator)
    segmentedPattern = pattern.split(@uriSeparator)
    if segmentedURI.length != segmentedPattern.length
      false
    else
      params = {}
      for i in [0..segmentedPattern.length-1]
        if segmentedPattern[i] != ""
          if segmentedPattern[i].indexOf(@parameterPrefix) == 0
            params[segmentedPattern[i].substr(@parameterPrefix.length)] = segmentedURI[i]
          else if segmentedPattern[i] != segmentedURI[i]
            # Explicit return breaks the function
            return false
      params
