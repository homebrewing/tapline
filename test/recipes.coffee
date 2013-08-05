assert = require 'assert'
db = require '../lib/db'
request = require 'supertest'
test = require '../lib/test'
util = require '../lib/util'

{app} = require '../lib/server'

authInfo = {}

describe '/v1/recipes.json', ->
    before (done) ->
        db.connect util.testDb, (err) ->
            if err then return done(err)

            test.setupAuth (err, user, client, auth) ->
                if err then return done(err)

                authInfo = {user, client, auth}

                done()

    after (done) ->
        db.close done

    describe 'Create recipes', ->
        it 'Should successfully create a new recipe', (done) ->
            request(app)
                .post('/v1/recipes.json')
                .send(private: false, recipe: {name: 'Test recipe', fermentables: [{name: 'Pale malt', weight: 3.2}]})
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect 200, done

    describe 'List recipes', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .get('/v1/recipes.json')
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()

        it 'Should return private recipes', (done) ->
            request(app)
                .get('/v1/recipes.json')
                .query(showPrivate: true)
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()