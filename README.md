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


## Server-side

```javascript
var http = require('http').Server();
var io = require("socket.io")(http);

var RestfulRouter = require("restful.io");

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
  // These are method names, feel free to change or to add
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
  // Nested methods are supported
  FOO: {
    BAR: [
      // Here, the method will be FOO:BAR (: is the default separator)
      // No route yet
    ]
  }
}, true);

router.start(io);

http.listen(8080);
```

## Client-side

You have two ways to deal with the client side.

### Client API

This is the preferred way. The second parameter of start method is a boolean. Set it to true on the server side as below :

```javascript
router.start(io, true);
```

Now on the client side, you can make a GET on /api to retrieve the code :


```javascript
var socket = io('http://localhost:8080');
socket.on('connect', function() {
  // Here we wait for API
  socket.on('GET:RESULT', function(data) {
    // You get JS code to eval
    var API = eval(data)(socket);

    // All
    API.GET("/user/1", {}, function(user) {
      console.log(JSON.stringify(user));
    });
  });

  // Asking for API
  socket.emit('GET', '/api');
});
```

By default, API's code is automagically generated using your routes. For nested methods, use subobjects :

```javascript
API.FOO.BAR; // Corresponds to nested method BAR inside FOO
```

Please note that every autogenerated function in API has the same signature :

```javascript
API.YOUR_METHOD(uri, jsonParams, callback)
```


##### Extending API

If you need to expose to client more API methods than autogenerated ones, just provide an APIController inside router context and create a method inside with the following signature :

```javascript
function get(API) {
  // Do your stuff and add your custom methods here
  // Remember that API code is sent WITHOUT the context, so never use variables which doesn't live in API context.
  return API;
}
```

### Raw Javascript

This method is dangerous. Because socket.io is asynchronous by nature, you can only have several handlers listening on the same event.

In restful.io, each request is associated with a unique ID. If you use raw Javascript, you will have to handle these identifiers manually.

Remember that if you don't provide any unique ID to socket.emit, other handlers might intercept your request's response too, which may end on unpredictable behaviours.

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
    // Here we provide a requestId
    requestId: 'REQUEST_1'
    uri: '/foo/j:user',
    json: {
      user: {
        name: "John Smith",
        age: 42
      }
    }
  });

  // We have to listen on PUT:requestId and not on PUT:RESULT
  // Actually, RESULT is the default requestId
  socket.on('PUT:REQUEST_1', function(data) {
    console.log("Result PUT : " + data);
  });
});
```

## And more

Here is described the usable parameters when constructing a router :

| Name | Type | Defaults | Example |
| ---- | ---- | -------- | ------  |
| ctx  | JSON | NA | { "FooController": FooController, "BarController": BarController } |
| routes | JSON | NA | Main JSON config. See snippet before |
| verbose | boolean | false | If true, much more log will appear |
| methodSeparator | character | ':' | Used for nested methods. |
| uriSeparator | character | '/' | Used to parse URIs. |
| parameterPrefix | string | "p:" | Used to identify primitive parameter. |
| jsonParameterPrefix | string | "j:" | Used to identify complex JSON parameter. |
| resultSuffix | string | "RESULT" | Used to return a nested method (GET:RESULT, POST:RESULT, ...) |

When you start the router, as a third parameter, you may use a callback to handle user connection :

```javascript
router.start(io, true, function(socket) {
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
