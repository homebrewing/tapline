assert = require 'assert'
db = require '../lib/db'
request = require 'supertest'
sinon = require 'sinon'
util = require '../lib/util'

{app} = require '../lib/server'
User = require '../lib/models/user'

describe '/v1/users.json', ->
    before (done) ->
        db.connect util.testDb, done

    after (done) ->
        User.remove {}, (err) ->
            if err then console.log err.toString()
            db.close done

    describe 'Register new user', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .post('/v1/users.json')
                .send(email: 'test@test.com', name: 'test_user', password: 'abc123')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.equal 'test_user', res.body.name

                    done()

    describe 'List users', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .get('/v1/users.json')
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body.users

                    done()

    describe 'Update user', ->
        it 'Should return JSON on success', (done) ->
            User.findOne (err, user) ->
                request(app)
                    .put('/v1/users.json')
                    .send(id: user.id, name: 'test_user_updated')
                    .expect('Content-Type', /json/)
                    .expect(200)
                    .end (err, res) ->
                        if err then return done(err)

                        assert.equal 'test_user_updated', res.body.name

                        done()

    describe 'Delete user', ->
        it 'Should return JSON on success', (done) ->
            User.findOne (err, user) ->
                request(app)
                    .del('/v1/users.json')
                    .send(id: user.id)
                    .expect('Content-Type', /json/)
                    .expect(200)
                    .end (err, res) ->
                        if err then return done(err)

                        assert.ok res.body.status

                        done()
