_ = require 'underscore'

Tokenizer = require './Tokenizer'
Session = require './Session'

module.exports = class SessionManager
  constructor: (@sessions = []) ->

  getSession: (token) => () =>
    _.find @sessions, (s) -> s.token == token

  createSession: (route) => (session = {}) =>
    token = Tokenizer.get()
    s = new Session(token)
    for k,v of session
      s.data[k] = v
    @sessions.push(s)
    route.bindSession @createSession(route), @getSession(token), @putSession(token)

  putSession: (token) => (session = {}) =>
    @sessions = _.map @sessions, (s) ->
      if s.token == token
        session
      else
        s

  handleRequest: (route, token, data) =>
    if route.public != true
      if token? && token != ""
        route.bindSession @createSession(route), @getSession(token), @putSession(token)
        session = @getSession(token)()
        if session?
          route.follow()
        else
          route.FORBIDDEN("Invalid token provided for private route : #{token}")
      else
        route.FORBIDDEN("No token provided for private route")
    else
      # Public routes
      route.bindSession @createSession(route)
      route.follow()
