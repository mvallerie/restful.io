_ = require 'underscore'

module.exports = class UserGroupAuthHandler
  constructor: (@groups, @users) ->

  handleRoutes: (routes) ->
    #for method,methodData of routes
    #  if Array.isArray(methodData)
    #    route = methodData
    #    if route.allowTo?
    #      for identifier in route.allowTo
    #        if _.contains(@groups, identifier) || _.contains(@users, identifier)
    #    else
    #  else if typeof methodData == "object"


  routeRequest: (request) ->
