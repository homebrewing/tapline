express = require 'express'
log = require './log'

# Import controllers
colorController = require './controllers/color'

# Setup HTTP server
app = exports.app = express()
app.configure ->
    app.disable 'x-powered-by'
    app.use express.responseTime()
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use require('./middleware/requestId')
    app.use require('./middleware/log')
    app.use app.router

# Define routes
app.get '/v1/convert/color.json', colorController.convert

# Start the server
exports.start = (listen, done) ->
    [host, port] = listen.split ':'
    port ?= 8080
    app.listen port, host
    log.info "Tapline server started on http://#{host}:#{port}"

    done?()
