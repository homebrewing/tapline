assert = require 'assert'
db = require '../lib/db'
queue = require '../lib/queue'
request = require 'supertest'
sinon = require 'sinon'
test = require '../lib/test'
util = require '../lib/util'

{app} = require '../lib/server'

Recipe = require '../lib/models/recipe'

RecipeUpdatedWorker = require '../lib/workers/recipe-updated'

authInfo = {}
recipeId = null

describe '/v1/recipes', ->
    before (done) ->
        sinon.stub queue, 'put'
        db.connect util.testDb, (err) ->
            if err then return done(err)

            test.setupAuth (err, user, client, auth) ->
                if err then return done(err)

                authInfo = {user, client, auth}

                done()

    after (done) ->
        queue.put.restore()
        Recipe.find().remove (err) ->
            if err then done(err)
            db.close done

    describe 'Create recipes', ->
        it 'Should successfully create a new recipe', (done) ->
            request(app)
                .post('/v1/recipes')
                .send(private: false, recipe: {name: 'Test recipe', fermentables: [{name: 'Pale malt', weight: 3.2}]})
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    recipeId = res.body.id

                    assert.ok res.body.slug
                    assert.ok res.body.user.name

                    done()

        it 'Should successfully clone a recipe with a unique slug', (done) ->
            request(app)
                .post('/v1/recipes')
                .send(private: false, recipe: {name: 'Test recipe', fermentables: [{name: 'Pale malt', weight: 3.2}]})
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.equal 'test-recipe-1', res.body.slug

                    done()

    describe 'List recipes', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .get('/v1/recipes')
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()

        it 'Should return private recipes', (done) ->
            request(app)
                .get('/v1/recipes')
                .query(showPrivate: true)
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()

        it 'Should get public recipes without auth', (done) ->
            request(app)
                .get('/v1/public/recipes')
                .expect('Content-Type', /json/)
                .expect 200, done

    describe 'Update recipes', ->
        it 'Should update a recipe successfully', (done) ->
            queue.put.reset()

            request(app)
                .put("/v1/recipes/#{recipeId}")
                .send(recipe: {name: 'Test Recipe', fermentables: [{name: 'Pale malt', weight: 3.4}]})
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.equal 'test-recipe', res.body.slug
                    assert.equal 3.4, res.body.data.fermentables[0].weight

                    assert.ok queue.put.calledOnce

                    done()

        it 'Should create/update actions in a background job', (done) ->
            worker = RecipeUpdatedWorker()

            workerData =
                id: recipeId
                user: authInfo.user.id
                private: false
                info:
                    name: 'Test Recipe'
                    slug: 'test-recipe'
                    description: '...'
                    og: 1.050
                    fg: 1.009
                    ibu: 23
                    abv: 5.4
                    color: 8

            worker.work workerData, (status) ->
                assert.equal 'success', status

                done()

    describe 'Delete recipes', ->
        it 'Should delete a recipe successfully', (done) ->
            request(app)
                .del("/v1/recipes/#{recipeId}")
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect 204, done
