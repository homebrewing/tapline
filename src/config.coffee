_ = require 'lodash'
log = require './log'
util = require 'util'

module.exports =
    # HTTP host/port to listen
    listen: 'localhost:2337'

    # MongoDB database URL
    dbUrl: 'mongodb://localhost/tapline'

    # Session cookie secret
    cookieSecret: 'COOKIE_SECRET'

    # OAuth2 app information for social logins
    facebookAppId: 'FACEBOOK_APP_ID'
    facebookAppSecret: 'FACEBOOK_APP_SECRET'

    googleConsumerKey: 'GOOGLE_CONSUMER_KEY'
    googleConsumerSecret: 'GOOGLE_CONSUMER_SECRET'

    # Load from a configuration object (e.g. a `require`d json file)
    load: (obj) ->
        log.debug "Loading config: #{util.inspect obj}"
        _.extend module.exports, obj
