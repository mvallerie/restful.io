var io = require('socket.io-client');

var socket = io('http://localhost:8080');
socket.on('connect', function() {
  socket.emit('PUT', {
    uri: '/user',
    json: {
      userdata: {
        name: "John Smith",
        age: 42
      }
    }
  });

  socket.on('PUT:RESULT', function(data) {
    console.log("PUT RESULT : " + JSON.stringify(data));

    socket.emit('GET', '/user/'+data.id);

    socket.on('GET:RESULT', function(data) {
      console.log("GET RESULT : " + JSON.stringify(data));
      socket.emit('DELETE', '/user/'+data.id);

      socket.on('DELETE:RESULT', function(data) {
        console.log("DELETE RESULT : " + JSON.stringify(data));
      });
    });

  });
});
