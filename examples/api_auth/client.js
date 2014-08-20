var io = require('socket.io-client');

var socket = io('http://localhost:8080');
socket.on('connect', function() {
  socket.on('GET:RESULT', function(api) {
    // This time, we set the verbose param to true so that you can see what's happening in the logs
    var API = eval(api.data)(socket, true);
    console.log("Got API");

    API.GET("/ping", {}, function(result) {
      console.log("Result for GET /ping : " + JSON.stringify(result));
    });

    API.GET("/api/login", {}, function(result) {
      // After this line you don't care about the token any more
      API.token = result.data;
      console.log("Result for GET /api/login (session token) : " + result.data);

      // It will work now because you got a valid auth token
      API.GET("/ping", {}, function(r) {
        console.log("Result for GET /ping (one more time): " + JSON.stringify(r));

        // Finally revokes the token
        API.GET("/api/logout", {}, function(result) {
          console.log("Result for GET /api/logout :" + JSON.stringify(result));
        });
      });
    });
  });

  socket.emit('GET', '/api');
});
