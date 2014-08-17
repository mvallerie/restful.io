var io = require('socket.io-client');

var socket = io('http://localhost:8080');
socket.on('connect', function() {
  socket.on('GET:RESULT', function(data) {
    var API = eval(data)(socket);
    console.log("Got API");

    API.GET("/user/1", {}, function(user) {
      console.log("Result for GET /user/1 : " + JSON.stringify(user));
      console.log("Now launching useless operation GET /user/useless");
      API.GET("/user/useless");
    });
  });

  socket.emit('GET', '/api');
});
