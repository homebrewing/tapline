# Ensure a user is logged in, otherwise redirect to login
# If the request method is not HTTP GET, then return a 403
module.exports = (req, res, next) ->
    if req.user then return next()

    if req.method is 'GET'
        res.redirect "/account/login?next=#{encodeURIComponent(req.url)}"
    else
        res.status(403).send('User must be logged in...')
