ensureLogin = require './middleware/ensure-login'
express = require 'express'
log = require './log'
passport = require 'passport'
path = require 'path'

# Authentication strategies
{BasicStrategy} = require 'passport-http'
BearerStrategy = require('passport-http-bearer').Strategy
LocalStrategy = require('passport-local').Strategy

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

loginController = require './controllers/account/login'
accountController = require './controllers/account/account'
oauthController = require './controllers/account/oauth'

# =================
# Setup HTTP server
# =================
app = exports.app = express()
app.configure ->
    app.disable 'x-powered-by'
    app.set 'views', path.normalize(path.join("#{__dirname}", '..', 'views'))
    app.set 'view engine', 'jade'
    app.use express.responseTime()
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use require('./middleware/requestId')
    app.use require('./middleware/log')
    # Web browser specific route middleware
    app.use '/account', express.cookieParser()
    app.use '/account', express.session(secret: 'l3jh4532khg52')
    app.use passport.initialize()
    app.use '/account', passport.session()
    app.use '/account', require('./middleware/user')
    app.use app.router
    app.use express.static(path.normalize(path.join("#{__dirname}", '..', 'public')))

# =====================
# Setup Auth Strategies
# =====================

# HTTP Basic
passport.use new BasicStrategy (username, password, done) ->
    User.findOne {name: username}, (err, user) ->
        if err then return done(err)
        if not user then return done(null, false)

        user.authenticate password, (err, success) ->
            if err then return done(err)
            if not success then return done('Invalid password')

            done(null, user)

# OAuth2 Bearer Token
passport.use new BearerStrategy (token, done) ->
    Authorization.findOne {token}, (err, auth) ->
        if err then return done(err)
        if not auth then return done(null, false)

        User.findById auth.userId, (err, user) ->
            if err then return done(err)
            if not user then return done(null, false)

            done(null, user, {scopes: auth.scopes})

# Local data store user/pass
passport.use new LocalStrategy (username, password, done) ->
    User.findOne name: username, (err, user) ->
        if err then return done(err)
        if not user then return done(null, false, {message: 'Incorrect username'})

        user.authenticate password, (err, success) ->
            if err then return done(err)
            if not success then return done(null, false, {message: 'Incorrect password'})

            done(null, user)

# User serialization for auth
passport.serializeUser (user, done) ->
    done null, user.id

passport.deserializeUser (id, done) ->
    User.findOne _id: id, (err, user) ->
        done err, user

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

app.post '/account/access_token', oauthController.postAccessToken

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

# HTML routes
app.get '/account/login', loginController.loginPage
app.post '/account/login', loginController.login
app.get '/account/logout', ensureLogin, loginController.logout

app.get '/account', ensureLogin, accountController.accountPage
app.post '/account', ensureLogin, accountController.updateAccount

app.get '/account/authorize', ensureLogin, oauthController.getAuthorization
app.post '/account/authorize', ensureLogin, oauthController.postAuthorization

# Start the server
exports.start = (listen, done) ->
    [host, port] = listen.split ':'
    port ?= 2337
    app.listen port, host
    log.info "Tapline server started on http://#{host}:#{port}"

    done?()
