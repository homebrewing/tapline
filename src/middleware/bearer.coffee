###
OAuth2 Bearer Token Auth Middleware
Returns a function which checks the bearer token of requests and
optionally requires a particular OAuth2 scope before moving on
to the next middleware.
###
passport = require 'passport'

authBearer = passport.authenticate('bearer', {session: false})

module.exports = (scope) ->
    return (req, res, next) ->
        authBearer req, res, (err) ->
            if err then return next(err)

            # No scope required? Move on to the next middleware
            if not scope then return next()

            if not req.authInfo or not req.authInfo.scopes
                res.status 401
                return next 'No scopes found for user'

            if req.authInfo.scopes.indexOf(scope) is -1
                res.status 401
                return next "Scope #{scope} not found for user"

            next()
