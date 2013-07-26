assert = require 'assert'
db = require '../lib/db'
request = require 'supertest'
sinon = require 'sinon'
test = require '../lib/test'
util = require '../lib/util'

{app} = require '../lib/server'

User = require '../lib/models/user'

authInfo = {}
cookie = null
grant = null
token = null

describe '/account', ->
    before (done) ->
        db.connect util.testDb, (err) ->
            if err then return done(err)

            test.setupAuth (err, user, client, auth) ->
                if err then return done(err)

                authInfo = {user, client, auth}

                done()

    after (done) ->
        db.close done

    describe 'Login', ->
        it 'Should return HTML on success', (done) ->
            request(app)
                .get('/account/login')
                .expect('Content-Type', /html/)
                .expect 200, done

        it 'Should log in a user and redirect', (done) ->
            request(app)
                .post('/account/login')
                .send(username: authInfo.user.name, password: 'abc123', next: '/account')
                .expect(302)
                .end (err, res) ->
                    if err then return done(err)

                    cookie = res.headers['set-cookie']

                    done()

    describe 'OAuth web flow', ->
        it 'Should render a grant request page', (done) ->
            request(app)
                .get('/account/authorize')
                .query(client_id: authInfo.client.id, scope: 'user,recipe', state: 'test')
                .set('Cookie', cookie)
                .expect('Content-Type', /html/)
                .expect 200, done

        it 'Should return a grant code and state to redirectUri', (done) ->
            request(app)
                .post('/account/authorize')
                .send(clientId: authInfo.client.id, scopes: 'user,recipe', state: 'test', redirectUri: 'foo')
                .set('Cookie', cookie)
                .expect(302)
                .expect('Location', /foo/)
                .expect('Location', /code/)
                .expect('Location', /state/)
                .end (err, res) ->
                    if err then return done(err)

                    grant = /code=([^&]+)/.exec(res.headers.location)[1]

                    if not grant then return done('Grant could not be extracted')

                    done()

        it 'Should return an access token from a grant code', (done) ->
            request(app)
                .post('/account/access_token')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret, code: grant)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    token = res.body.token

                    done()

        it 'Should return the same access token on subsequent requests', (done) ->
            request(app)
                .post('/account/access_token')
                .send(clientId: authInfo.client.id, clientSecret: authInfo.client.secret, code: grant)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.equal token, res.body.token

                    done()

    describe 'Logout', ->
        it 'Should lot a user out', (done) ->
            request(app)
                .get('/account/logout')
                .set('Cookie', cookie)
                .expect 302, done
