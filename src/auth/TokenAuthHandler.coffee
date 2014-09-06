_ = require 'underscore'

Tokenizer = require './Tokenizer'

module.exports = class TokenAuthHandler
  constructor: (@tokens = []) ->

  handleRoutes: (routes) =>
    @routes = routes

  handleRequest: (route, data) =>
    if route.token? && _(@tokens).contains(route.token)
      route.follow()
    else
      route.FORBIDDEN("Authentication failed for token: #{route.token}")


  login: (route, data) =>
    token = Tokenizer.get()
    @tokens.push(token)
    route.OK(token)

  logout: (route) =>
    @tokens = _(@tokens).filter (e) -> e != route.token
    route.OK()
