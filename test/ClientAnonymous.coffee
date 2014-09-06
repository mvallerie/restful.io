io = require 'socket.io-client'

module.exports = (callback) ->

  socket = io('http://localhost:4242')
  socket.on 'connect', () ->
    socket.emit('GET', '/api')

    socket.on 'GET:RESULT', (apiSrc) ->
      API = eval(apiSrc.data)(socket, true)
      callback(API)
