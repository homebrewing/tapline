# Enable CORS for requests
module.exports = (req, res, next) ->
    res.header 'Access-Control-Allow-Origin', '*'
    res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE'
    res.header 'Access-Control-Allow-Headers', 'Content-Type, Authorization'

    if req.method is 'OPTIONS'
        res.send 200
    else
        next()
