config = require '../config'
db = require '../db'
log = require '../log'

connected = false

# Setup the database if not already connected
module.exports = (done) ->
    if not connected
        log.setup()
        
        db.connect config.dbUrl, (err) ->
            if err then return console.log(err)
            connected = true
            done?()
    else
        done?()
