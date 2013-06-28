mongoose = require 'mongoose'

exports.connect = (dbUrl, done) ->
    mongoose.connect dbUrl

    mongoose.connection.on 'error', console.error.bind(console, 'connection error: ')
    mongoose.connection.once 'open', ->
        done?()
