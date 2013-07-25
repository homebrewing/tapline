# Expose the user object to templates
module.exports = (req, res, next) ->
    if req.user then res.locals.user = req.user
    next()
