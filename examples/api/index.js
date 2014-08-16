var RestfulRouter = require("../../index");
var http = require('http').Server();
var io = require("socket.io")(http);

var log = function(str) {
  console.log("[LOG] api example: " + str);
};


var UserController = {
  get: function(id) {
    log("UserController received request GET for " + id);
    return id;
  }
};

// Here we go with the router

var ControllerScope = {
  "UserController": UserController
};

var router = new RestfulRouter(ControllerScope, {
  GET: [
    {
      uri: "/user/p:id",
      to: "UserController.get(id)"
    }
  ]
}, true);

router.start(io, true);

// Connections will be established on port 8080
http.listen(8080);
