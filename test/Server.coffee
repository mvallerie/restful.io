module.exports = (controllers, routes) ->
  http = require('http').createServer (req, res) ->
    res.writeHead(200, {'Content-Type': 'text/plain'})
    res.end()

  io = require('socket.io')(http)
  RestfulRouter = require('../index')

  router = new RestfulRouter(controllers, routes, true)
  router.start(io, true)

  http.listen 4242
