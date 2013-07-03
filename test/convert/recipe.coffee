assert = require 'assert'
brauhaus = require 'brauhaus'
request = require 'supertest'
sinon = require 'sinon'

{app} = require '../../lib/server'

describe 'Recipe Conversion', ->
    it 'Should respond with JSON on success', (done) ->
        request(app)
            .post('/v1/convert/recipe.json')
            .send(format: 'json', recipes: [{name: 'foo'}], outputFormat: 'beerxml')
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err then return done(err)

                assert.ok res.body.format
                assert.ok res.body.recipes

                done()

    it 'Should have a default output format', (done) ->
        request(app)
            .post('/v1/convert/recipe.json')
            .send(format: 'json', recipes: [{name: 'foo'}])
            .expect(200, done)

    it 'Should require a valid input format', (done) ->
        request(app)
            .post('/v1/convert/recipe.json')
            .send(recipes: [{name: 'foo'}], outputFormat: 'beerxml')
            .expect(400, done)

    it 'Should require an input value', (done) ->
        request(app)
            .post('/v1/convert/recipe.json')
            .send(format: 'json', outputFormat: 'beerxml')
            .expect(400, done)

    inputFormatMap =
        'beerxml': 'fromBeerXml'

    for format, method of inputFormatMap
        do (format, method) ->
            it "Should call Recipe.#{method} for input format '#{format}'", (done) ->
                sinon.spy brauhaus.Recipe, method

                request(app)
                    .post("/v1/convert/recipe.json")
                    .send(format: format, recipes: ['<recipes><recipe><name>foo</name></recipe></recipes>'], outputFormat: 'json')
                    .expect(200)
                    .end (err, res) ->
                        if err then return done(err)

                        assert.ok brauhaus.Recipe[method].called

                        brauhaus.Recipe[method].restore()
                        done()

    outputFormatMap =
        'json': 'toJSON'
        'beerxml': 'toBeerXml'

    for format, method of outputFormatMap
        do (format, method) ->
            it "Should call Recipe.prototype.#{method} for output format '#{format}'", (done) ->
                sinon.spy brauhaus.Recipe.prototype, method

                request(app)
                    .post('/v1/convert/recipe.json')
                    .send(format: 'json', recipes: [{name: 'foo'}], outputFormat: format)
                    .expect(200)
                    .end (err, res) ->
                        if err then return done(err)

                        assert.ok brauhaus.Recipe.prototype[method].called

                        brauhaus.Recipe.prototype[method].restore()
                        done()
