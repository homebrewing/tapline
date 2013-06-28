assert = require 'assert'
brauhaus = require 'brauhaus'
request = require 'supertest'
sinon = require 'sinon'

{app} = require '../lib/server'

describe 'Color Conversion', ->
    it 'Should respond with JSON on success', (done) ->
        request(app)
            .post('/v1/color/srm')
            .send(format: 'ebc', value: 39)
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err then return done(err)

                assert.ok res.body.format
                assert.ok res.body.value

                done()

    it 'Should require a valid output format', (done) ->
        request(app)
            .post('/v1/color/foo')
            .send(format: 'ebc', value: 39)
            .expect(400, done)

    it 'Should require a valid input format', (done) ->
        request(app)
            .post('/v1/color/srm')
            .send(value: 39)
            .expect(400, done)

    it 'Should require an input value', (done) ->
        request(app)
            .post('/v1/color/srm')
            .send(format: 'ebc')
            .expect(400, done)

    it 'Should require input value to be a number', (done) ->
        request(app)
            .post('/v1/color/srm')
            .send(format: 'ebc', value: 'foo')
            .expect(400, done)

    inputFormatMap =
        'ebc': 'ebcToSrm'
        'lovibond': 'lovibondToSrm'

    for format, method of inputFormatMap
        do (format, method) ->
            it "Should call brauhaus.#{method} for input format '#{format}'", (done) ->
                sinon.spy brauhaus, method

                request(app)
                    .post("/v1/color/srm")
                    .send(format: format, value: 20)
                    .expect(200)
                    .end (err, res) ->
                        if err then return done(err)

                        assert.ok brauhaus[method].called

                        brauhaus[method].restore()
                        done()

    outputFormatMap =
        'ebc': 'srmToEbc'
        'lovibond': 'srmToLovibond'
        'name': 'srmToName'
        'rgb': 'srmToRgb'
        'css': 'srmToCss'

    for format, method of outputFormatMap
        do (format, method) ->
            it "Should call brauhaus.#{method} for output format '#{format}'", (done) ->
                sinon.spy brauhaus, method

                request(app)
                    .post("/v1/color/#{format}")
                    .send(format: 'srm', value: 20)
                    .expect(200)
                    .end (err, res) ->
                        if err then return done(err)

                        assert.ok brauhaus[method].called

                        brauhaus[method].restore()
                        done()
