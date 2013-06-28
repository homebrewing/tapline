crypto = require 'crypto'

# A middleware that gives each request a mostly unique identifier
# The ID is exposed in the response with the X-Request-ID header
module.exports = (req, res, next) ->
    crypto.pseudoRandomBytes 4, (err, buffer) ->
        if err then next(err)

        req.id = buffer.toString 'hex'
        res.header 'X-Request-ID', req.id
        next()
