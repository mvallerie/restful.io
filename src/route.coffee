ss = require 'socket.io-stream'

module.exports = class RestfulRoute
  constructor: (@ctx, @method, @uri, @public, @stream, @routeHandler, @params, @parameterPrefix, @endCallback, @verbose = false, @session = {}, @headers = {}) ->
    @outStream = null

  log: (str) =>
    if @verbose then console.log "[LOG] RestfulRoute #{@method} #{@uri} : #{str}"

  OK: (data = {}) =>
    @endCallback {status: 200, headers: @headers, data: data}, @outStream

  FORBIDDEN: (err = "(empty)") =>
    @log "FORBIDDEN"
    @endCallback {status: 403, err: err}, @outStream

  ISE: (err = "(empty)") =>
    @log "INTERNAL_SERVER_ERROR"
    @endCallback {status: 500, err: err}, @outStream

  NOT_FOUND: (err = "(empty)") =>
    @log "NOT_FOUND"
    @endCallback {status: 404, err: err}, @outStream

  bindSession: (@createSession, @getSession, @putSession) =>
    @

  withSession: (s = {}) =>
    @putSession(s)
    @

  withNewSession: (s = {}) =>
    @createSession(s).withHeader("token", @getSession().token)

  withHeader: (k, v) =>
    @headers[k] = v
    @

  withStream: (_stream) =>
    @outStream = _stream.pipe(ss.createStream())
    @

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
          if arg.indexOf(@parameterPrefix) == 0
            @params[arg.substr(@parameterPrefix.length)]
          else
            arg
        )
    if @stream? then paramStack.push(@stream)
    if @getSession? then paramStack.push(@getSession())
    paramStack
