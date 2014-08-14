restful.io
==========

restful.io has been designed to develop quickly a realtime routing system for your "RESTful-like" apps. It's using [socket.io](https://github.com/Automattic/socket.io) but the module does not depend on it

Inspirations
------------
- [Play Framework 2](https://github.com/playframework/playframework)
- [Express.io](https://github.com/techpines/express.io)
- RESTful architectures

Installation
------------
`npm install --save restful.io`

Overview
-----
Below is a quick presentation of the module. You may check examples subdir for more.


#### Server-side

```javascript
var http = require('http').Server();
var io = require("socket.io")(http);

var RestfulRouter = require("../work/restful.io/index");

var FooController = {
  bar: function(param) {
    console.log("FooController.bar("+param+");");
    return "OK";
  },
  barJson: function(jsonParam) {
    console.log("FooController.barJson("+JSON.stringify(jsonParam)+");");
    return "OK";
  }
};

// This ugly stuff is actually used to have a way to link route string and JS object
var ControllerScope = {
  "FooController": FooController
};

var router = new RestfulRouter(ControllerScope, {
  // These are event names, feel free to change or to add
  // Here I used GET/PUT/DELETE only to mimic classic RESTful app
  GET: [
    {
      // p:varname indicates a primitive type parameter
      // Parameter names are bound between uri and route handler
      uri: "/foo/p:param",
      to: "FooController.bar(param)"
    }
    // You can add as many more routes as you wish
  ],
  PUT: [
    {
      // j:varname indicates a JSON object parameter
      uri: "/foo/j:param",
      to: "FooController.barJson(param)"
    }
  ],
  POST: [
    // No route yet
  ],
  DELETE: [
    // No route yet
  ],
  // Nesting events are supported
  FOO: {
    BAR: [
      // Here, the event will be FOO:BAR (: is the default separator)
      // No route yet
    ]
  }
}, true);

router.start(io);

http.listen(8080);
```
#### Client-side

```javascript
var io = require('socket.io-client');

var socket = io('http://localhost:8080');
socket.on('connect', function() {
  // For primitive parameters, you can pass it directly in the URI
  socket.emit('GET', '/foo/4');

  socket.on('GET:RESULT', function(data) {
    console.log("Result GET : " + data);
  });

  // For complex JSON parameter, you have to send a plain JSON object corresponding the format below
  // The name of your parameter is used to retrieve the value
  socket.emit('PUT', {
    uri: '/foo/j:user',
    json: {
      user: {
        name: "John Smith",
        age: 42
      }
    }
  });

  socket.on('PUT:RESULT', function(data) {
    console.log("Result PUT : " + data);
  });
});
```

#### And more

Here is described the usable parameters when constructing a router :

| Name | Type | Defaults | Example |
| ---- | ---- | -------- | ------  |
| ctx  | JSON | NA | { "FooController": FooController, "BarController": BarController } |
| routes | JSON | NA | Main JSON config. See snippet before |
| verbose | boolean | false | If true, much more log will appear |
| eventSeparator | character | ':' | Used for nested events. |
| uriSeparator | character | '/' | Used to parse URIs. |
| parameterPrefix | string | "p:" | Used to identify primitive parameter. |
| jsonParameterPrefix | string | "j:" | Used to identify complex JSON parameter. |
| resultSuffix | string | "RESULT" | Used to return a nested event (GET:RESULT, POST:RESULT, ...) |

When you start the router, as a second parameter, you may use a callback to handle user connection :

```javascript
router.start(io, function(socket) {
  console.log("User connected on : " + socket);
});
```

Warranty
--------
restful.io is currently under heavy development. I'm building this project for myself and i try to make the code as clean as possible (which is far away from now :)). Feel free to submit a PR. Same for this README.

#### Known limitations
- Route parsing is poor and must be rewritten
- Error handling is very approximative
- socket.io only

#### Currently working on
- Known limitations
- Better parameters model
- File support
- Get rid of the context object

#### Ideas for later
- Get rid of socket.io to use raw Websockets ?
- Client module ?
