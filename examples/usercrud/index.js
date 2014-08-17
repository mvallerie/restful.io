var RestfulRouter = require("../../index");
var http = require('http').Server();
var io = require("socket.io")(http);
var _ = require("underscore");

var log = function(str) {
  console.log("[LOG] usercrud example: " + str);
};

var UserId = 0;
var UserStore = [];

var UserController = {
  get: function(id, result) {
    log("UserController received request GET for " + id);
    result(_.filter(UserStore, function(e) {
      return e.id == id;
    })[0]);
  },
  put: function(data, result) {
    var user = data;
    if(user.id !== undefined) {
      log("UserController received request PUT for " + user.name + " (" + user.id + ")");
      var stored = _.filter(UserStore, function(e) {
        return e.id == user.id;
      });
      if(stored.length == 1) {
        stored[0].name = user.name;
        stored[0].age = user.age;
      }
    } else {
      log("UserController received request PUT for " + user.name + " (new)");
      user.id = UserId;
      UserStore.push(user);
      UserId = UserId + 1;
    }
    return result(user);
  },
  delete: function(id, result) {
    log("UserController received request DELETE for " + id);
    var before = UserStore.length;
    UserStore = _.filter(UserStore, function(e) { return e.id != id; });
    return result({deleted: before - UserStore.length});
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
  ],
  PUT: [
    {
      uri: "/user/j:data",
      to: "UserController.put(data)"
    }
  ],
  DELETE: [
    {
      uri: "/user/p:id",
      to: "UserController.delete(id)"
    }
  ]
}, true);

router.start(io);

// Connections will be established on port 8080
http.listen(8080);
