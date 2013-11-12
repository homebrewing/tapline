assert = require 'assert'
config = require '../lib/config'

describe 'Config', ->
    it 'Should load from object', ->
        loaded = config.load {foo: 1}

        # Returned value should be extended config
        assert.equal 1, loaded.foo

        # Config itself should have been extended
        assert.equal 1, config.foo
