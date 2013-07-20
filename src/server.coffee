express = require 'express'
log = require './log'
passport = require 'passport'

# Authentication strategies
{BasicStrategy} = require 'passport-http'
BearerStrategy = require('passport-http-bearer').Strategy

Authorization = require './models/authorization'
User = require './models/user'

# Import controllers
colorConvertController = require './controllers/convert/color'
durationConvertController = require './controllers/convert/duration'
recipeConvertController = require './controllers/convert/recipe'
recipeCalculateController = require './controllers/calculate/recipe'

authController = require './controllers/authorizations'
userController = require './controllers/user'
actionController = require './controllers/actions'

# =================
# Setup HTTP server
# =================
app = exports.app = express()
app.configure ->
    app.disable 'x-powered-by'
    app.use express.responseTime()
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use require('./middleware/requestId')
    app.use require('./middleware/log')
    app.use passport.initialize()
    #app.use passport.session()
    app.use app.router

# =====================
# Setup Auth Strategies
# =====================
passport.use new BasicStrategy (username, password, done) ->
    User.findOne {name: username}, (err, user) ->
        if err then return done(err)
        if not user then return done(null, false)

        user.authenticate password, (err, success) ->
            if err then return done(err)
            if not success then return done('Invalid password')

            done(null, user)

passport.use new BearerStrategy (token, done) ->
    Authorization.findOne {token}, (err, auth) ->
        if err then return done(err)
        if not auth then return done(null, false)

        User.findById auth.userId, (err, user) ->
            if err then return done(err)
            if not user then return done(null, false)

            done(null, user, {scopes: auth.scopes})

# =============
# Define routes
# =============
authBasic = passport.authenticate('basic', {session: false})
authBearer = require './middleware/bearer'

# Public routes
app.post '/v1/convert/color.json', colorConvertController.convert
app.post '/v1/convert/duration.json', durationConvertController.convert
app.post '/v1/convert/recipe.json', recipeConvertController.convert
app.post '/v1/calculate/recipe.json', recipeCalculateController.calculate

app.post '/v1/users.json', userController.create

# Basic authenticated routes
app.post '/v1/authorizations.json', authBasic, authController.create
app.get '/v1/authorizations.json', authBasic, authController.list
app.put '/v1/authorizations/:id.json', authBasic, authController.update
app.delete '/v1/authorizations/:id.json', authBasic, authController.delete

# OAuth2 Authenticated routes
app.get '/v1/users/:id?.json', authBearer(), userController.list
app.put '/v1/users/:id.json', authBearer('user'), userController.update
app.delete '/v1/users/:id.json', authBearer('user:delete'), userController.delete

app.get '/v1/actions/:id?.json', authBearer(), actionController.list

# Start the server
exports.start = (listen, done) ->
    [host, port] = listen.split ':'
    port ?= 2337
    app.listen port, host
    log.info "Tapline server started on http://#{host}:#{port}"

    done?()
