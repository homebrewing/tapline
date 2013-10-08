assert = require 'assert'
brauhaus = require 'brauhaus'
request = require 'supertest'
sinon = require 'sinon'

{app} = require '../../lib/server'

describe 'Duration Conversion', ->
    it 'Should respond with JSON on success', (done) ->
        request(app)
            .post('/v1/convert/duration')
            .send(values: ['1 min 15 seconds'], outputFormat: 'minutes')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err then return done(err)

                assert.ok res.body.format
                assert.ok res.body.values

                done()

    it 'Should convert multiple values', (done) ->
        request(app)
            .post('/v1/convert/duration')
            .send(values: [1, 63, 1600], outputFormat: 'display')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                assert.equal 3, res.body.values.length
                done()

    it 'Should have a default output format', (done) ->
        request(app)
            .post('/v1/convert/duration')
            .send(values: [39])
            .expect(200, done)

    it 'Should require at least one input value', (done) ->
        request(app)
            .post('/v1/convert/duration')
            .send(values: [], outputFormat: 'minutes')
            .expect(400, done)

    describe 'Input parsing', (done) ->
        before ->
            sinon.spy brauhaus, 'parseDuration'

        it 'Should call parseDuration to parse input durations', (done) ->
            request(app)
                .post('/v1/convert/duration')
                .send(values: [23, '5 minutes', '1h 2m'])
                .expect(200)
                .end (err, res) ->
                    assert.equal 3, brauhaus.parseDuration.callCount
                    done()

        after ->
            brauhaus.parseDuration.restore()

    outputFormatMap =
        'display': 'displayDuration'

    for format, method of outputFormatMap
        do (format, method) ->
            describe "Output format '#{format}'", ->
                before ->
                    sinon.spy brauhaus, method

                it "Should call brauhaus.#{method}", (done) ->
                    request(app)
                        .post('/v1/convert/duration')
                        .send(values: [20], outputFormat: format)
                        .expect(200)
                        .end (err, res) ->
                            if err then return done(err)

                            assert.ok brauhaus[method].called
                            done()

                after ->
                    brauhaus[method].restore()
