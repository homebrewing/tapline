winston = require 'winston'

log = module.exports = new winston.Logger()

# Setup logging transports - by default log messages go nowhere
log.setup = ->
    log.add winston.transports.Console,
        colorize: true
