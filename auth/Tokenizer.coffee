_ = require 'underscore'
crypto = require 'crypto'

$this = module.exports

@get = () ->
  hash = crypto.createHash 'sha512'

  seedLen = 128
  _.chain([1..seedLen]).map (e) ->
    String.fromCharCode e
  .each (e) ->
    hash.update e

  hash.digest 'hex'
