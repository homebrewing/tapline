fivebeans = require 'fivebeans'

client = null

# Connect to the queue server
exports.connect = (host, port, done) ->
    client = new fivebeans.client host, port
    client.on 'connect', ->
        client.use 'tapline', done

    client.on 'error', done

    client.connect()

# Create a new job
exports.put = (type, payload, options, done) ->
    # Support calling with only two or three arguments (no options, no callback)
    if options instanceof Function
        done = options
        options = {}
    
    options ?= {}
    options.priority ?= 50
    options.delay ?= 0
    options.ttr ?= 120

    done ?= -> false

    client.put options.priority, options.delay, options.ttr, JSON.stringify({type, payload}), done
