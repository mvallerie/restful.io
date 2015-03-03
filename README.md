restful.io
==========

restful.io is a micro framework built on the shoulders of [socket.io](http://socket.io). It was designed to get HTTP possibilities, without using HTTP itself. By using socket.io, transport layer is made completely abstract.

I started this project because i needed a simple way to manage realtime routing on the server side. I do believe that a very light client (pure HTML and JS), communicating with the server layer using realtime technologies is a very good and extremely portable paradigm.

Inspirations
------------
- [Play Framework 2](https://github.com/playframework/playframework)
- [Express.io](https://github.com/techpines/express.io)
- RESTful architectures
- [HTTP](http://fr.wikipedia.org/wiki/Hypertext_Transfer_Protocol)

Installation
------------
`npm install --save restful.io`

Main features
------------
* Routing system
* Session management
* Client API (needs to be improved)
* File upload (using [socket.io-stream](https://www.npmjs.com/package/socket.io-stream))

What does it look like
-----
Below is a quick presentation of the module in Coffeescript. You may check test folder for more.


### Routing

```coffeescript
io = require('socket.io')(http)
RestfulRouter = require "restful.io"

controllers = {
  UserController: {
    findAll: (route) ->
      route.OK("All users")
    create: (route, user) ->
      route.OK("User #{user.id} has been created")
  }
}

router = new RestfulRouter(controllers, {
  GET: [
    {
      uri: "/user"
      to: "UserController.findAll()"
      public: true
    }
  ]
  PUT: [
    {
      uri: "/user"
      to: "UserController.create(p:user)"
      public: true
    }
  ]
}, true)

router.start(io)
```

### Session management

No "public" attributes for routes. Those routes are considered as "private", which means you need a valid session to access them. When you will get it, it will be automagically injected on private routes.

```coffeescript
controllers = {
  UserController: {
    login: (route, credentials) ->
      route.withNewSession({username: credentials.username}).OK("You are now logged in")
    me: (route, session) ->
      route.OK("Welcome back #{session.username}")
  }
}

router = new RestfulRouter(controllers, {
  POST: [
    {
      uri: "/login"
      to: "UserController.login(p:credentials)"
      public: true
    }
  ]
  GET: [
    {
      uri: "/me"
      to: "UserController.me()"
    }
  ]
}, true)

router.start(io)
```

### Client API

On the client side, you may create this file :

```coffeescript
io = require 'socket.io-client'
ss = require 'socket.io-stream'

module.exports = (callback) ->
  socket = io('http://yourdomain.com:1234')
  socket.on 'connect', () ->
    socket.emit('GET:/api')

    socket.on 'GET:RESULT', (apiSrc) ->
      API = eval(apiSrc.data)(socket, ss, true)
      callback(API)
```

Then :

```coffeescript
require("./yourfile.coffee") (API) ->
  # Feel free to use API object :)
  API.POST '/login', {credentials: {username: 'foobar'}}, (result) ->
    # Here we set the "token" (session id)
    API.token = result.headers.token
    API.GET '/me', {}, (result) ->
      console.log result.data
```

### File upload

TODO



API
----

### Server

##### Route object

| Method | Parameters | Effect | Example |
| ---- | ---- | -------- | ------  |
| OK  | data: * | Sends back data to the client with a 200 result | route.OK({message: "done"}) |
| FORBIDDEN | err: * | Sends back err to the client with a 403 result | route.FORBIDDEN("Error !!") |
| ISE | err: * | Sends back err to the client with a 500 result | route.ISE("Error !!") |
| NOT_FOUND | err: * | Sends back err to the client with a 404 result | route.NOT_FOUND("Error !!") |

##### Result object

| Property | Possible values |
| -------- | ----------------- |
| status  | 200, 403, 500, 404 |
| data | any string |
| headers | JS object, used for token |

### Client

##### API object

API object is automatically generated from your routes. Basically, the way to call a route is :

```coffeescript
API.METHOD '/route/you.want', {param:"foobar"}, (result) ->
  # Use the result here
```

The only special property you have to worry about is "token" which is your session id.

Tests
----
```shell
npm test
```


Warranty
--------
restful.io is currently under heavy development. I'm building this project for myself and i try to make the code as clean as possible (which is far away from now :)). Feel free to submit a PR. Same for this README.


Currently working on
---------
- Add some examples
- True client API
- File support
- Using socket.io namespaces
