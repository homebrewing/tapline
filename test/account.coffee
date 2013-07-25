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

    describe 'Login / logout', ->
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

        it 'Should lot a user out', (done) ->
            request(app)
                .get('/account/logout')
                .set('Cookie', cookie)
                .expect 302, done
