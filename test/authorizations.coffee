assert = require 'assert'
db = require '../lib/db'
request = require 'supertest'
sinon = require 'sinon'
test = require '../lib/test'
util = require '../lib/util'

{app} = require '../lib/server'

Authorization = require '../lib/models/authorization'

authInfo = {}
newAuthId = null

describe '/v1/authorizations.json', ->
    before (done) ->
        db.connect util.testDb, (err) ->
            if err then return done(err)

            test.setupAuth (err, user, client, auth) ->
                if err then return done(err)

                authInfo = {user, client, auth}

                done()

    after (done) ->
        Authorization.remove {_id: newAuthId}, (err) ->
            if err then return done(err)
            db.close done

    describe 'Create a new authorization', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .post('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret)
                .expect('Content-Type', /json/)
                .expect(201)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body
                    assert.ok res.body.token

                    newAuthId = res.body.id

                    done()

        it 'Should return error on missing basic auth', (done) ->
            request(app)
                .post('/v1/authorizations.json')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret)
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
                .send(clientId: authInfo.client.id, clientSecret: 'invalid')
                .expect 401, done

        it 'Should require client id', (done) ->
            request(app)
                .post('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .send(clientSecret: authInfo.client.secret)
                .expect 400, done

        it 'Should require client secret', (done) ->
            request(app)
                .post('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id)
                .expect 400, done

    describe 'List authorizations', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .get('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .query(clientId: authInfo.client.id, clientSecret: authInfo.client.secret)
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()

        it 'Should return error on missing basic auth', (done) ->
            request(app)
                .get('/v1/authorizations.json')
                .query(clientId: authInfo.client.id, clientSecret: authInfo.client.secret)
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
                .query(clientId: authInfo.client.id, clientSecret: 'invalid')
                .expect 401, done

        it 'Should require client id', (done) ->
            request(app)
                .get('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .query(clientSecret: authInfo.client.secret)
                .expect 400, done

        it 'Should require client secret', (done) ->
            request(app)
                .get('/v1/authorizations.json')
                .auth(authInfo.user.name, 'abc123')
                .query(clientId: authInfo.client.id)
                .expect 400, done

    describe 'Update authorizations', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret, scopes: ['test1', 'test2'])
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()

        it 'Should return error on missing basic auth', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret, scopes: [])
                .expect 401, done

        it 'Should return error on invalid client id', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: 'invalid', clientSecret: authInfo.client.secret, scopes: [])
                .expect 401, done

        it 'Should return error on invalid client secret', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: 'invalid', scopes: [])
                .expect 401, done

        it 'Should require client id', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientSecret: authInfo.client.secret, scopes: [])
                .expect 400, done

        it 'Should require client secret', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, scopes: [])
                .expect 400, done

        it 'Should require scopes', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret)
                .expect 400, done

        it 'Should set scopes', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret, scopes: ['test1'])
                .expect 200, done

        it 'Should add scopes', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret, addScopes: ['test2', 'test3'])
                .expect(200)
                .end (err, res) ->
                    items = ['test1', 'test2', 'test3']

                    for x in [0...items.length]
                        assert.equal items[x], res.body.scopes[x]

                    done()

        it 'Should remove scopes', (done) ->
            request(app)
                .put("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret, removeScopes: ['test2', 'test3'])
                .expect(200)
                .end (err, res) ->
                    items = ['test1']

                    for x in [0...items.length]
                        assert.equal items[x], res.body.scopes[x]

                    done()

    describe 'Delete an authorization', ->
        it 'Should return error on missing basic auth', (done) ->
            request(app)
                .del("/v1/authorizations/#{newAuthId}.json")
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret)
                .expect 401, done

        it 'Should return error on invalid client id', (done) ->
            request(app)
                .del("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: 'invalid', clientSecret: authInfo.client.secret)
                .expect 401, done

        it 'Should return error on invalid client secret', (done) ->
            request(app)
                .del("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: 'invalid')
                .expect 401, done

        it 'Should require client id', (done) ->
            request(app)
                .del("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientSecret: authInfo.client.secret)
                .expect 400, done

        it 'Should require client secret', (done) ->
            request(app)
                .del("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id)
                .expect 400, done

        it 'Should return JSON on success', (done) ->
            request(app)
                .del("/v1/authorizations/#{newAuthId}.json")
                .auth(authInfo.user.name, 'abc123')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret)
                .expect 204, done
