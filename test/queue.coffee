assert = require 'assert'
fivebeans = require 'fivebeans'
sinon = require 'sinon'
queue = require '../lib/queue'

# Mock the FiveBeans client
class MockClient
    on: (event, done) ->
        if event is 'connect'
            @connectDone = done

    connect: ->
        @connectDone()

    use: (tube, done) ->
        done()

    put: (pri, delay, ttr, payload, done) ->
        done()

describe 'Work Queue', ->
    origClient = null

    before ->
        origClient = fivebeans.client
        fivebeans.client = MockClient

    after ->
        fivebeans.client = origClient

    it 'Should connect to Beanstalkd', (done) ->
        queue.connect 'server', 11300, (err) ->
            done()

    it 'Should put an item', (done) ->
        queue.put 'type', {some: 'data'}, {ttr: 30}, (err, id) ->
            assert !err
            done()

    it 'Should put without options', (done) ->
        queue.put 'type', {some: 'data'}, (err, id) ->
            assert !err
            done()

    it 'Should put without options or callback', (done) ->
        queue.put 'type', {some: 'data'}
        done()
