###
Test Utilities
###

Authorization = require './models/authorization'
Client = require './models/client'
User = require './models/user'

# Create the auth test user
ensureUser = (done) ->
    User.findOne {name: 'auth_user'}, (err, user) ->
        if err then return done(err)
        if user then return done(null, user)

        # Create the user if not found
        user = new User
            email: 'auth@test.com'
            name: 'auth_user'

        user.setPassword 'abc123', (err) ->
            if err then return done(err)
            user.save (err, user) ->
                if err then return done(err)
                done(null, user)

# Create a new API client
ensureClient = (user, done) ->
    Client.findOne {name: 'Auth Test'}, (err, client) ->
        if err then return done(err)
        if client
            if client.userId isnt user.id
                # Values may change between runs, so make sure they
                # are set properly after load. This could happen if
                # the user is accidentally deleted and recreated,
                # for example.
                client.userId = user.id
                client.save (err, client) ->
                    if err then return done(err)
                    return done(null, client)
            else
                return done(null, client)
        else
            # Create the client if not found
            client = new Client
                userId: user.id
                name: 'Auth Test'

            client.save (err, client) ->
                if err then return done(err)
                done(null, client)

# Create the test authorization
ensureAuth = (user, client, done) ->
    scopes = ['user', 'user:email', 'user:delete']

    Authorization.findOne {token: 'authTest'}, (err, auth) ->
        if err then return done(err)
        if auth
            if auth.userId isnt user.id or auth.clientId isnt client.id or auth.scopes.toString() isnt scopes.toString()
                # Values may change between runs, so make sure they
                # are set properly after load. This could happen if
                # the user is accidentally deleted and recreated,
                # for example.
                auth.userId = user.id
                auth.clientId = client.id
                auth.scopes = scopes
                
                auth.save (err, auth) ->
                    if err then return done(err)
                    return done(null, auth)
            else
                return done(null, auth)
        else
            # Create the authorization if not found
            auth = new Authorization
                token: 'authTest'
                userId: user.id
                clientId: client.id
                scopes: scopes

            auth.save (err, auth) ->
                if err then return done(err)
                done(null, auth)

# Setup auth for running tests so that authenticated API calls can
# be called successfully. Callback takes an err, user, client, and
# authorization. This can be called many times safely.
exports.setupAuth = (done) ->
    ensureUser (err, user) ->
        if err then return done(err)
        ensureClient user, (err, client) ->
            if err then return done(err)
            ensureAuth user, client, (err, auth) ->
                if err then return done(err)
                done(null, user, client, auth)
