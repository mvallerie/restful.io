module.exports = class RestfulRouter

  constructor: (@ctx, @routes, @verbose = false, @eventSeparator = ':', @uriSeparator = '/', @parameterPrefix = 'p:', @jsonParameterPrefix = 'j:', @resultSuffix = "RESULT") ->

  log: (str) ->
    console.log "[LOG] RestfulRouter: #{str}"

  start: (io, beforeRouting = undefined) =>
    @log "Router started"
    io.on "connection", (socket) =>
      beforeRouting?(socket)
      if @verbose then @log "New client connected"
      @bindRoutes(@routes, socket)


  # TODO All the following needs some functional refactoring

  bindRoutes: (routes, socket, nestedIn = undefined) =>
    for event, eventData of @routes
      if Array.isArray(eventData)
        @bindEvent socket, event, eventData
      else if typeof eventData == "object"
        @bindRoutes eventData, socket, if nestedIn? then "#{nestedIn}#{@eventSeparator}#{event}" else event

  bindEvent: (socket, eventName, eventData) ->
    if @verbose then @log "Binding #{eventName}"
    socket.on eventName, (data) =>
      uri = if typeof data == "string" then data else data.uri
      json = if typeof data == "string" then {} else data.json

      if @verbose then @log "Received request #{eventName} #{uri}"
      for route in eventData
        params = @matchURI(uri, json, route.uri)
        if params
          routeHandler = route.to
          if @verbose then @log "Calling #{routeHandler} for #{eventName} #{uri}"
          socket.emit "#{eventName}#{@eventSeparator}#{@resultSuffix}", @evalRouteHandler(routeHandler, params)
          return
      if @verbose then @log "No route found for #{eventName} #{uri}"

  ###
  bindParams: (params, to) =>
    for pname, pval of params
      to = to.replace(pname, JSON.stringify(pval))
      to = to.replace(pname, pval)
    to
  ###

  # TODO Needs regexp and / or good parsing method
  matchURI: (uri, jsonParams, pattern) =>
    segmentedURI = uri.split(@uriSeparator)
    segmentedPattern = pattern.split(@uriSeparator)
    if segmentedURI.length != segmentedPattern.length
      false
    else
      params = {}
      for i in [0..segmentedURI.length-1]
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
