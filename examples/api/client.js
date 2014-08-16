var io = require('socket.io-client');

var socket = io('http://localhost:8080');
socket.on('connect', function() {
  socket.on('GET:RESULT', function(data) {
    var API = eval(data)(socket);
    console.log("Got API");

    API.GET("/user/1", {}, function(user) {
      console.log(JSON.stringify(user));
    });
  });

  socket.emit('GET', '/api');
});
