assert = require 'assert'
db = require '../lib/db'
request = require 'supertest'
sinon = require 'sinon'
test = require '../lib/test'
util = require '../lib/util'

{app} = require '../lib/server'

authInfo = {}

describe '/v1/authorizations.json', ->
    before (done) ->
        db.connect util.testDb, (err) ->
            if err then return done(err)

            test.setupAuth (err, user, client, auth) ->
                if err then return done(err)

                authInfo = {user, client, auth}

                done()

    after (done) ->
        db.close done

    describe 'Create a new authorization', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .post('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.key, clientSecret: authInfo.client.secret)
                .expect('Content-Type', /json/)
                .expect(201)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()

        it 'Should return error on missing basic auth', (done) ->
            request(app)
                .post('/v1/authorizations.json')
                .send(clientId: authInfo.client.key, clientSecret: authInfo.client.secret)
                .expect 401, done

        it 'Should return error on invalid client id', (done) ->
            request(app)
                .post('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: 'invalid', clientSecret: authInfo.client.secret)
                .expect 401, done

        it 'Should return error on invalid client secret', (done) ->
            request(app)
                .post('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.key, clientSecret: 'invalid')
                .expect 401, done

    describe 'List authorizations', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .get('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .query(clientId: authInfo.client.key, clientSecret: authInfo.client.secret)
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()

        it 'Should return error on missing basic auth', (done) ->
            request(app)
                .get('/v1/authorizations.json')
                .query(clientId: authInfo.client.key, clientSecret: authInfo.client.secret)
                .expect 401, done

        it 'Should return error on invalid client id', (done) ->
            request(app)
                .get('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .query(clientId: 'invalid', clientSecret: authInfo.client.secret)
                .expect 401, done

        it 'Should return error on invalid client secret', (done) ->
            request(app)
                .get('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .query(clientId: authInfo.client.key, clientSecret: 'invalid')
                .expect 401, done

