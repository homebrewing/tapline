log = require '../log'

# A Connect/Express middleware that does two things related to logging:
# 1. Log information about each incoming request and its response status
# 2. Install logging methods into the request object that are aware of
#    the request ID and log it anytime a message is logged, making it
#    possible to track parallel requests in the logs.
module.exports = (req, res, next) ->
    end = res.end

    startTime = Date.now()

    # Install request ID aware logging
    for method in ['info', 'warn', 'error']
        do (method) ->
            req[method] = (message, meta) ->
                if meta
                    log[method] "#{req.id} #{message}", meta
                else
                    log[method] "#{req.id} #{message}"

    res.end = (chunk, encoding) ->
        # Call original method
        res.end = end
        res.end chunk, encoding

        # Log message
        message = "#{req.id} #{req.ip} #{req.method} #{req.path} #{res.statusCode} #{req.headers['user-agent'] or '-'}"

        # Select info, warning, or error based on HTTP status
        if res.statusCode < 400
            log.info message
        else if res.statusCode < 500
            log.warn message
        else
            log.error message

    next()
