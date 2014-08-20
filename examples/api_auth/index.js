var RestfulRouter = require("../../index");
var http = require('http').Server();
var io = require("socket.io")(http);

var log = function(str) {
  console.log("[LOG] api (with auth) example: " + str);
};


var PingController = {
  ping: function(route) {
    log("UserController received request GET on ping()");
    route.OK("pong");
  }
};

// Here we go with the router

var ControllerScope = {
  "PingController": PingController
};

// No public attribute, route is auth reserved.
var router = new RestfulRouter(ControllerScope, {
  GET: [
    {
      uri: "/ping",
      to: "PingController.ping()"
    }
  ]
}, true);

// Instead of true you can specify your own login handler (which looks like a controller, see the doc for more)
// This is recommended because default login handler logs in every request
router.start(io, true);

// Connections will be established on port 8080
http.listen(8080);
