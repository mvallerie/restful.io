var RestfulRouter = require("../../index");
var http = require('http').Server();
var io = require("socket.io")(http);

var log = function(str) {
  console.log("[LOG] api example: " + str);
};


var UserController = {
  // result is a callback, you can omit it if your route does not return anything
  get: function(id, andThen) {
    log("UserController received request GET for " + id);
    andThen({id: id, name: "John Smith", age: 42});
  },
  // omit result param so this route can not return anything
  useless: function() {
    log("UserController received request GET for useless method");
  }
};

// Here we go with the router

var ControllerScope = {
  "UserController": UserController
};

var router = new RestfulRouter(ControllerScope, {
  GET: [
    {
      uri: "/user/useless",
      to: "UserController.useless()"
    },
    {
      uri: "/user/p:id",
      to: "UserController.get(id)"
    }
  ]
}, true);

router.start(io, true);

// Connections will be established on port 8080
http.listen(8080);
