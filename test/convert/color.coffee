assert = require 'assert'
brauhaus = require 'brauhaus'
request = require 'supertest'
sinon = require 'sinon'

{app} = require '../lib/server'

describe 'Color Conversion', ->
    it 'Should respond with JSON on success', (done) ->
        request(app)
            .post('/v1/convert/color.json')
            .send(format: 'ebc', values: [39], outputFormat: 'srm')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err then return done(err)

                assert.ok res.body.format
                assert.ok res.body.values

                done()

    it 'Should convert multiple values', (done) ->
        request(app)
            .post('/v1/convert/color.json')
            .send(format: 'ebc', values: [39, 25, 14], outputFormat: 'srm')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                assert.equal 3, res.body.values.length
                done()

    it 'Should have a default output format', (done) ->
        request(app)
            .post('/v1/convert/color.json')
            .send(format: 'ebc', values: [39])
            .expect(200, done)

    it 'Should require a valid input format', (done) ->
        request(app)
            .post('/v1/convert/color.json')
            .send(values: [39], outputFormat: 'srm')
            .expect(400, done)

    it 'Should require at least one input value', (done) ->
        request(app)
            .post('/v1/convert/color.json')
            .send(format: 'ebc', outputFormat: 'srm')
            .expect(400, done)

    it 'Should require input values to be numbers', (done) ->
        request(app)
            .post('/v1/convert/color.json')
            .send(format: 'ebc', values: ["foo"])
            .expect(400, done)

    inputFormatMap =
        'ebc': 'ebcToSrm'
        'lovibond': 'lovibondToSrm'

    for format, method of inputFormatMap
        do (format, method) ->
            it "Should call brauhaus.#{method} for input format '#{format}'", (done) ->
                sinon.spy brauhaus, method

                request(app)
                    .post("/v1/convert/color.json")
                    .send(format: format, values: [20], outputFormat: 'srm')
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
                    .post('/v1/convert/color.json')
                    .send(format: 'srm', values: [20], outputFormat: format)
                    .expect(200)
                    .end (err, res) ->
                        if err then return done(err)

                        assert.ok brauhaus[method].called

                        brauhaus[method].restore()
                        done()
