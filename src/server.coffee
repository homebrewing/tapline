config = require './config'
ensureLogin = require './middleware/ensure-login'
express = require 'express'
session = require 'express-session'
responseTime = require 'response-time'
methodOverride = require 'method-override'
cookieParser = require 'cookie-parser'
log = require './log'
passport = require 'passport'
path = require 'path'

MongoStore = require('connect-mongo')(session)

# Authentication strategies
{BasicStrategy} = require 'passport-http'
BearerStrategy = require('passport-http-bearer').Strategy
LocalStrategy = require('passport-local').Strategy
FacebookStrategy = require('passport-facebook').Strategy
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy

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
recipeController = require './controllers/recipes'

loginController = require './controllers/account/login'
accountController = require './controllers/account/account'
oauthController = require './controllers/account/oauth'

# =================
# Setup HTTP server
# =================
app = exports.app = express()
app.disable 'x-powered-by'
app.set 'views', path.normalize(path.join("#{__dirname}", '..', 'views'))
app.set 'view engine', 'jade'
app.use '/v1', require('./middleware/cors')
app.use responseTime()
app.use express.urlencoded()
app.use express.json()
app.use methodOverride()
app.use require('./middleware/requestId')
app.use require('./middleware/log')
# Web browser specific route middleware
app.use '/account', cookieParser()
app.use '/account', session
    extended: true
    resave: true
    saveUninitialized: true
    secret: config.cookieSecret
    store: new MongoStore
        url: 'mongodb://localhost/tapline'
        db: 'tapline'
        useNewUrlParser: true

app.use passport.initialize()
app.use '/account', passport.session()
app.use '/account', require('./middleware/user')
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

# Social login with Facebook
passport.use new FacebookStrategy {
    clientID: config.facebookAppId
    clientSecret: config.facebookAppSecret
    callbackURL: 'https://api.malt.io/account/authorize/facebook/callback'
    },
    (accessToken, refreshToken, profile, done) ->
        User.findOrCreateExternal "fb:#{profile.id}", profile, done

# Social login with Google
passport.use new GoogleStrategy {
    clientID: config.googleConsumerKey
    clientSecret: config.googleConsumerSecret
    callbackURL: 'https://api.malt.io/account/authorize/google/callback'
    },
    (accessToken, refreshToken, profile, done) ->
        profile.photos = [{value: "https://plus.google.com/s2/photos/profile/#{profile.id}?sz=SIZE"}]

        User.findOrCreateExternal "g:#{profile.id}", profile, done

# =============
# Define routes
# =============
authBasic = passport.authenticate('basic', {session: false})
authBearer = require './middleware/bearer'

# Public routes
app.post '/v1/convert/color', colorConvertController.convert
app.post '/v1/convert/duration', durationConvertController.convert
app.post '/v1/convert/recipe', recipeConvertController.convert
app.post '/v1/calculate/recipe', recipeCalculateController.calculate

app.post '/v1/users', userController.create

app.post '/account/access_token', require('./middleware/cors'), oauthController.postAccessToken

app.get '/v1/public/users/:id?', userController.list
app.get '/v1/public/actions/:id?', actionController.list
app.get '/v1/public/recipes/:id?', recipeController.list
#app.get '/v1/public/recipes/:id/history/:hid?', recipeController.history

# Basic authenticated routes
app.post '/v1/authorizations', authBasic, authController.create
app.get '/v1/authorizations', authBasic, authController.list
app.put '/v1/authorizations/:id', authBasic, authController.update
app.delete '/v1/authorizations/:id', authBasic, authController.delete

# OAuth2 Authenticated routes
app.get '/v1/profile', authBearer(), userController.profile
app.get '/v1/users/:id?', authBearer(), userController.list
app.put '/v1/users/:id', authBearer('user'), userController.update
app.delete '/v1/users/:id', authBearer('user:delete'), userController.delete

app.get '/v1/actions/:id?', authBearer(), actionController.list

app.get '/v1/recipes/:id?', authBearer(), recipeController.list
app.post '/v1/recipes', authBearer('recipe'), recipeController.create
app.put '/v1/recipes/:id', authBearer('recipe'), recipeController.update
app.delete '/v1/recipes/:id', authBearer('recipe'), recipeController.delete

# app.get '/v1/recipes/:id/history/:hid?', authBearer('recipe'), recipeController.history

# HTML routes
app.get '/account/login', loginController.loginPage
app.post '/account/login', loginController.login('local')
app.get '/account/logout', ensureLogin, loginController.logout

app.get '/account', ensureLogin, accountController.accountPage
app.post '/account', ensureLogin, accountController.updateAccount

app.get '/account/authorize', ensureLogin, oauthController.getAuthorization
app.post '/account/authorize', ensureLogin, oauthController.postAuthorization

app.get '/account/authorize/facebook', passport.authenticate('facebook', scope: 'email')
app.get '/account/authorize/facebook/callback', loginController.login('facebook')

app.get '/account/authorize/google', passport.authenticate('google', scope: 'openid email profile')
app.get '/account/authorize/google/callback', loginController.login('google')

app.get '/', (req, res) ->
    res.status(200).sendfile "#{path.dirname(__dirname)}/public/apidoc.html"

# Start the server
exports.start = (listen, done) ->
    [host, port] = listen.split ':'
    port ?= 2337
    app.listen port, host
    log.info "Tapline server started on http://#{host}:#{port}"

    done?()
