assert = require 'assert'
brauhaus = require 'brauhaus'
request = require 'supertest'
sinon = require 'sinon'
util = require '../../lib/util'

{app} = require '../../lib/server'

recipeList = [
    {name: 'foo', fermentables: [{weight: 1}], spices: [{aa: 4.5, weight: 0.0028}]}
]

describe 'Recipe Calculation', ->
    it 'Should respond with JSON on success', (done) ->
        request(app)
            .post('/v1/calculate/recipe.json')
            .send(format: 'json', recipes: recipeList)
            .expect('Content-Type', /json/)
            .expect(200)
            .end (err, res) ->
                if err then return done(err)

                assert.ok res.body.length
                assert.ok res.body[0].og
                assert.ok res.body[0].fg
                assert.ok res.body[0].ibu
                assert.ok res.body[0].abv

                done()

    it 'Should require a valid input format', (done) ->
        request(app)
            .post('/v1/calculate/recipe.json')
            .send(recipes: recipeList)
            .expect(400, done)

    it 'Should require a valid input recipe list', (done) ->
        request(app)
            .post('/v1/calculate/recipe.json')
            .send(format: 'json')
            .expect(400, done)

    describe 'Dependent calls', ->
        before ->
            sinon.spy brauhaus.Recipe.prototype, 'calculate'
            sinon.spy brauhaus.Recipe.prototype, 'timeline'

        it 'Should call Recipe.prototype.calculate', (done) ->
            request(app)
                .post('/v1/calculate/recipe.json')
                .send(format: 'json', recipes: recipeList)
                .end (err, res) ->
                    assert.ok brauhaus.Recipe.prototype.calculate.called
                    done()

        it 'Should call Recipe.prototype.timeline', (done) ->
            request(app)
                .post('/v1/calculate/recipe.json')
                .send(format: 'json', recipes: recipeList)
                .end (err, res) ->
                    assert.ok brauhaus.Recipe.prototype.timeline.called
                    done()

        after ->
            brauhaus.Recipe.prototype.calculate.restore()
            brauhaus.Recipe.prototype.timeline.restore()

    describe 'Input parsing', (done) ->
        before ->
            sinon.spy util, 'getRecipeList'

        it 'Should call getRecipeList to parse recipes', (done) ->
            request(app)
                .post('/v1/calculate/recipe.json')
                .send(format: 'json', recipes: [{name: 'foo'}])
                .expect(200)
                .end (err, res) ->
                    assert.ok util.getRecipeList.called
                    done()

        after ->
            util.getRecipeList.restore()
