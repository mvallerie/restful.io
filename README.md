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
  // each method of your controllers has to take the route as first parameter
  bar: function(route, param) {
    console.log("FooController.bar("+param+");");
    // Here we route the request
    route.OK("OK");
  },
  // Your route does not return anything, omit result callback
  barJson: function(route, jsonParam) {
    console.log("FooController.barJson("+JSON.stringify(jsonParam)+");");
    // You don't call any of the route's methods so no response
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
    },
    // CAREFUL !! Route order matters.
    // The following route will never get matched because 'useless' will be treated as 'param' for first route
    {
      uri: "/foo/useless",
      to: "FooController.neverCalled()"
    }
    // You can add as many more routes as you wish
  ],
  PUT: [
    {
      // j:varname indicates a JSON object parameter
      // That means that the client have to send something which looks like => {user: {/* data */}}
      uri: "/foo",
      to: "FooController.barJson(j:user)"
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

### Route object methods and attrs

By convention, upper case identifiers end the route and send back something to client.
Lowercase identifiers does not end the route.

| Name | Parameters | Effect | Example |
| ---- | ---- | -------- | ------  |
| OK  | data: * | Sends back data to the client with a 200 result | route.OK({message: "done"}) |
| FORBIDDEN | err: String | Sends back data to the client with a 403 result | route.FORBIDDEN("Error !!") |
| follow | NA | If the route is not yet processed, "follow" sends the request to its routeHandler. This is useful with AuthHandlers | route.follow() |
| token | NA | If you are authentified, you can access the token. | route.token |

## Client-side

You have two ways to deal with the client side.

### Client API

This is the preferred way. The second parameter of start method is a boolean. Set it to true on the server side as below :

```javascript
router.start(io, true);
```

#### Authentication note

By default, when client API is exposed, every request has to be authenticated.
Default authentication handler is bound on uri /api/login and is very permissive : no credentials needed.

But actually this boolean parameter can be set to any valid AuthHandler. A valid AuthHandler looks like a controller designed for authentication purposes :

```javascript
router.start(io, {
  // Warning : Pseudocode below :)

  handleRoutes: function(routes) -> nothing

  handleRequest: function(route, data) -> nothing (you have to call one of the route methods)

  login: function(route, data) -> nothing (you have to call one of the route methods)

  logout: function(route) -> nothing (you have to call one of the route methods)
});
```

If you need to know more about that, please read auth/TokenAuthHandler.coffee

In case you need public API without any kind of authentication, just put a "public" attribute to true for each route you want to expose :

```javascript
routes = {
  GET: [
    {
      uri: "/iam/public",
      to: "IamController.public()",
      public: true
    }
  ]
}
```

Now on the client side, you can make a GET on /api to retrieve the code :


```javascript
var socket = io('http://localhost:8080');
socket.on('connect', function() {
  // Here we wait for API
  socket.on('GET:RESULT', function(apiSrc) {
    // You get JS code to eval
    var API = eval(apiSrc)(socket);

    // If you don't use authentication, skip this call
    API.GET("/api/login", {}, function(result) {
      // You HAVE to do the following.
      API.token = r.data;
      // Now forget about the authentication.......

      console.log("Now logged in");
      // Get foo 1
      API.GET("/foo/1", {}, function(result) {
        console.log("Result GET : " + JSON.stringify(result));

        API.PUT("/foo", {
          user: {
            name: "John Smith",
            age: 42
          }
        }, function(result) {
          console.log("Result PUT : " + JSON.stringify(result));

          // ...........until now :)
          API.GET("/api/logout", {}, function(result) {
            console.log("Now logged off");
          });
        });

      });

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
  // Note : this method is synchronous. No need for "andThen" callback. But don't forget to return valid API object !
  // Remember that API code is sent WITHOUT the context, so never use variables which doesn't live in API context.
  return API;
}
```


### Raw Javascript (with socket.io-client)

This method is dangerous. Because socket.io is asynchronous by nature, you can have several handlers listening on the same event.

In restful.io, each request is associated with a unique ID. If you use raw Javascript, you will have to handle these identifiers manually.

Remember that if you don't provide any unique ID to socket.emit, other handlers listening for response might intercept your request's response too, potentially conflicting with yours, which may end on unpredictable behaviours.

```javascript
var socket = io('http://localhost:8080');
socket.on('connect', function() {
  // For simple parameters, you can pass it directly in the URI
  socket.emit('GET', '/foo/4');

  socket.on('GET:RESULT', function(data) {
    console.log("Result GET : " + data);
  });

  // For complex parameters, you have to send a plain JSON object corresponding the format below
  // The name of your parameter is used to retrieve the value
  socket.emit('PUT', {
    // Here we provide a requestId
    requestId: 'REQUEST_1'
    // If the request is authenticated, put this param too
    token: 'foo',
    uri: '/foo',
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
| ctx  | JSON Object | NA | { "FooController": FooController, "BarController": BarController } |
| routes | JSON Object | NA | Main JSON config. See snippet before |
| verbose | boolean | false | If true, much more log will appear |
| methodSeparator | character | ':' | Used for nested methods. |
| uriSeparator | character | '/' | Used to parse URIs. |
| parameterPrefix | string | "p:" | Used to identify primitive parameter in route URI. |
| jsonParameterPrefix | string | "j:" | Used to identify complex JSON parameter in route handler call. |
| resultSuffix | string | "RESULT" | Default requestId fired to client if requestId not provided (GET:RESULT, POST:RESULT, ...) |

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
- Authentication
- Known limitations
- File support
- Get rid of the context object

#### Ideas for later
- Get rid of socket.io to use raw Websockets ?
- Client module ?
