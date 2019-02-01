winston = require 'winston'

log = module.exports = winston.createLogger()

# Setup logging transports - by default log messages go nowhere
log.setup = ->
    log.add new winston.transports.Console(),
        colorize: true
