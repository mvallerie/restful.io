#Q = require 'q'
chai = require 'chai'
#chaiAsPromised = require 'chai-as-promised'
#chai.use(chaiAsPromised)
chai.should()

_ = require 'underscore'
fs = require 'fs'

# Basic server definition ##########################################
####################################################################
####################################################################
controllers = {
  FooController: {
    foo: (route) ->
      route.OK("bar")
    bar: (route, bar) ->
      route.OK(bar)
    private: (route) ->
      route.OK("private")
    login: (route) ->
      route.withNewSession({username: 'foo'}).OK()
    me: (route, session) ->
      route.OK(session.data.username)
    upFile: (route, stream, session) ->
      chunks = []
      stream.on 'data', (chunk) ->
        chunks.push chunk
      stream.on 'end', () ->
        # Do something with chunks
        route.OK({url: "files/file.txt"})
      stream.on 'error', () ->
        route.ISE()
  }
}

routes = {
  GET: [
    {
      uri: "/foo"
      to: "FooController.foo()"
      public: true
    },
    {
      uri: "/bar"
      to: "FooController.bar(p:something)"
      public: true
    },
    {
      uri: "/private"
      to: "FooController.private()"
    },
    {
      uri: "/login"
      to: "FooController.login()"
      public: true
    },
    {
      uri: "/me"
      to: "FooController.me()"
    }
  ],
  POST: [
    {
      uri: "/upFile"
      to: "FooController.upFile()"
      stream: true
    }
  ]
}

require('./Server')(controllers, routes)
####################################################################
####################################################################
####################################################################

client = require('./ClientAnonymous')

describe 'Router', () ->
  API = undefined

  before (done) ->
    client (_API) ->
      API = _API
      done()

  describe '#BasicRoute', () ->
    it 'should return OK { bar }', (done) ->
      API.GET '/foo', {}, (result) ->
        try
          result.should.have.property 'status', 200
          result.should.have.property 'data', 'bar'
          done()
        catch e
          done(e)

    it 'should return OK { foobar }', (done) ->
      API.GET '/bar', {something: "foobar"}, (result) ->
        try
          result.should.have.property 'status', 200
          result.should.have.property 'data', 'foobar'
          done()
        catch e
          done(e)

    it 'should return FORBIDDEN', (done) ->
      API.GET '/private', {}, (result) ->
        try
          result.should.have.property 'status', 403
          done()
        catch e
          done(e)

    it 'should store data in session and return OK', (done) ->
      API.GET '/login', {}, (result) ->
        try
          result.should.have.property 'status', 200
          result.should.have.property 'data'
          API.token = result.headers.token

          API.GET '/me', {}, (result) ->
            try
              result.should.have.property 'status', 200
              result.should.have.property 'data', 'foo'
              done()
            catch e
              done(e)
        catch e
          done(e)


    it 'should return OK { private }', (done) ->
      API.GET '/private', {}, (result) ->
        try
          result.should.have.property 'status', 200
          result.should.have.property 'data', 'private'
          done()
        catch e
          done(e)

    it 'should send asynchronously file.txt to the server', (done) ->
      API.stream(fs.createReadStream('test/resources/file.txt')).POST '/upFile', {}, (result) ->
        try
          result.should.have.property 'status', 200
          result.should.have.property 'data'
          result.data.should.have.property 'url'
          done()
        catch e
          done(e)
