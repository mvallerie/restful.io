var RestfulRouter = require("../../index");
var http = require('http').Server();
var io = require("socket.io")(http);

var log = function(str) {
  console.log("[LOG] api example: " + str);
};


var UserController = {
  // route is an object (see in the doc) always coming first !
  get: function(route, id) {
    log("UserController received request GET for " + id);
    // Sends back OK result with data
    route.OK({id: id, name: "John Smith", age: 42});
  },
  // this method does nothing, so will never send answer
  useless: function(route) {
    log("UserController received request GET for useless method");
  }
};

// Here we go with the router

var ControllerScope = {
  "UserController": UserController
};

// This time, we use public api. So our routes are private by default (for security purposes)
// Specify public attribute on routes to bypass auth process
var router = new RestfulRouter(ControllerScope, {
  GET: [
    {
      uri: "/user/useless",
      to: "UserController.useless()",
      public: true
    },
    {
      uri: "/user/p:id",
      to: "UserController.get(id)",
      public: true
    }
  ]
}, true);

router.start(io, true);

// Connections will be established on port 8080
http.listen(8080);
