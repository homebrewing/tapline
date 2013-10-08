assert = require 'assert'
db = require '../lib/db'
request = require 'supertest'
test = require '../lib/test'
util = require '../lib/util'

{app} = require '../lib/server'

authInfo = {}

describe '/v1/actions', ->
    before (done) ->
        db.connect util.testDb, (err) ->
            if err then return done(err)

            test.setupAuth (err, user, client, auth) ->
                if err then return done(err)

                authInfo = {user, client, auth}

                done()

    after (done) ->
        db.close done

    describe 'List user actions', ->
        it 'Should return JSON on success', (done) ->
            request(app)
                .get('/v1/actions')
                .set('Authorization', "Bearer #{authInfo.auth.token}")
                .expect('Content-Type', /json/)
                .expect(200)
                .end (err, res) ->
                    if err then return done(err)

                    assert.ok res.body

                    done()

        it 'Should get public user actions without auth', (done) ->
            request(app)
                .get('/v1/public/actions')
                .expect('Content-Type', /json/)
                .expect 200, done
