module.exports = class RestfulRoute
  constructor: (@ctx, @method, @uri, @routeHandler, @params, @jsonParams, @jsonParameterPrefix, @endCallback, @verbose = false) ->

  log: (str) ->
    if @verbose then console.log "[LOG] RestfulRoute #{@method} #{uri} : #{str}"

  OK: (data = {}) =>
    @endCallback {status: 200, data: data}

  FORBIDDEN: (err = "(empty)") =>
    @log "FORBIDDEN"
    @endCallback {status: 403, err: err}

  ISE: (err = "(empty)") =>
    @log "INTERNAL_SERVER_ERROR"
    @endCallback {status: 500, err: err}

  NOT_FOUND: (err = "(empty)") =>
    @log "NOT_FOUND"
    @endCallback {status: 404, err: err}


  # TODO REALLY needs REGEXP...quick and dirty work
  follow: () =>
    startCS = @routeHandler.indexOf('.')
    endCS = @routeHandler.indexOf('(')
    endArgs = @routeHandler.lastIndexOf(')')

    handlerObj = @ctx[@routeHandler.substr(0, startCS)]
    callstack = @routeHandler.substr(startCS+1, endCS-startCS-1)
    args = @routeHandler.substr(endCS+1, endArgs-(endCS+1))
    handlerMethod = handlerObj

    for call in callstack.split('.')
      handlerMethod = handlerMethod?[call]

    paramStack = @getParamStack args

    handlerMethod?.apply(handlerMethod, paramStack)

  getParamStack: (args) =>
    paramStack = [@]
    if args != ""
      for arg in args.split(',')
        arg = arg.trim()
        paramStack.push(
          if arg.indexOf(@jsonParameterPrefix) == 0
            @jsonParams[arg.substr(@jsonParameterPrefix.length)]
          else
            @params[arg]
        )
    paramStack
