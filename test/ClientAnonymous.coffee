io = require 'socket.io-client'
ss = require 'socket.io-stream'

module.exports = (callback) ->

  socket = io('http://localhost:4242')
  socket.on 'connect', () ->
    socket.emit('GET:/api')

    socket.on 'GET:RESULT', (apiSrc) ->
      API = eval(apiSrc.data)(socket, ss, true)
      callback(API)
