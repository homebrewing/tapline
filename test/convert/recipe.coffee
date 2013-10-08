assert = require 'assert'
brauhaus = require 'brauhaus'
request = require 'supertest'
sinon = require 'sinon'
util = require '../../lib/util'

{app} = require '../../lib/server'

describe 'Recipe Conversion', ->
    it 'Should respond with JSON on success', (done) ->
        request(app)
            .post('/v1/convert/recipe')
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
            .post('/v1/convert/recipe')
            .send(format: 'json', recipes: [{name: 'foo'}])
            .expect(200, done)

    it 'Should require a valid input format', (done) ->
        request(app)
            .post('/v1/convert/recipe')
            .send(recipes: [{name: 'foo'}], outputFormat: 'beerxml')
            .expect(400, done)

    it 'Should require an input value', (done) ->
        request(app)
            .post('/v1/convert/recipe')
            .send(format: 'json', outputFormat: 'beerxml')
            .expect(400, done)

    describe 'Input parsing', (done) ->
        before ->
            sinon.spy util, 'getRecipeList'

        it 'Should call getRecipeList to parse recipes', (done) ->
            request(app)
                .post('/v1/convert/recipe')
                .send(format: 'json', recipes: [{name: 'foo'}], outputFormat: 'json')
                .expect(200)
                .end (err, res) ->
                    assert.ok util.getRecipeList.called
                    done()

        after ->
            util.getRecipeList.restore()

    outputFormatMap =
        'json': 'toJSON'
        'beerxml': 'toBeerXml'

    for format, method of outputFormatMap
        do (format, method) ->
            describe "Output format '#{format}'", ->
                before ->
                    sinon.spy brauhaus.Recipe.prototype, method

                it "Should call Recipe.#{method}", (done) ->
                    request(app)
                        .post('/v1/convert/recipe')
                        .send(format: 'json', recipes: [{name: 'foo'}], outputFormat: format)
                        .expect(200)
                        .end (err, res) ->
                            if err then return done(err)

                            assert.ok brauhaus.Recipe.prototype[method].called
                            done()

                after ->
                    brauhaus.Recipe.prototype[method].restore()
