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
        @timeout 10000

        db.connect util.testDb, (err) ->
            if err then return done(err)

            test.setupAuth (err, user, client, auth) ->
                if err then return done(err)

                authInfo = {user, client, auth}

                done()

    after (done) ->
        db.close done

    describe 'Require auth', ->
        it 'Should redirect to login for HTTP GET', (done) ->
            request(app)
                .get('/account')
                .expect(302)
                .expect 'Location', /\/account\/login/, done

        it 'Should 403 for HTTP POST', (done) ->
            request(app)
                .post('/account')
                .expect 403, done

    describe 'Login', ->
        it 'Should return HTML on success', (done) ->
            @timeout 5000

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

        it 'Should return a grant code and state to redirectUri: web_server', (done) ->
            request(app)
                .post('/account/authorize')
                .send(clientId: authInfo.client.id, scopes: 'user,recipe', state: 'test', redirectUri: 'foo', type: 'web_server')
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

        it 'Should return a grant code to redirectUri: token', (done) ->
            request(app)
                .post('/account/authorize')
                .send(clientId: authInfo.client.id, scopes: 'user,recipe', state: 'test', redirectUri: 'foo', type: 'token')
                .set('Cookie', cookie)
                .expect(302)
                .expect('Location', /foo/)
                .expect('Location', /access_token/)
                .expect('Location', /authTest/)
                .end (err, res) ->
                    if res
                        assert !err, "#{res.status}: #{res.text}"

                    done err

        it 'Should return 404 on bad client ID', (done) ->
            request(app)
                .post('/account/authorize')
                .send(clientId: '00826cdc7aeb4816b2000000', scopes: 'user,recipe', state: 'test', redirectUri: 'foo', type: 'token')
                .set('Cookie', cookie)
                .expect 404, done

        it 'Should return 400 on bad token request type', (done) ->
            request(app)
                .post('/account/authorize')
                .send(clientId: authInfo.client.id, scopes: 'user,recipe', state: 'test', redirectUri: 'foo', type: 'bad')
                .set('Cookie', cookie)
                .expect 400, done

        it 'Should return an access token from a grant code', (done) ->
            request(app)
                .post('/account/access_token')
                .send(client_id: authInfo.client.id, client_secret: authInfo.client.secret, code: grant)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    token = res.body.token

                    done()

        it 'Should return the same access token on subsequent requests', (done) ->
            request(app)
                .post('/account/access_token')
                .send(client_id: authInfo.client.id, client_secret: authInfo.client.secret, code: grant)
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
