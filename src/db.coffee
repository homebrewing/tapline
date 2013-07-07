mongoose = require 'mongoose'

# Remove internal fields from JSON documents
mongoose.Document::_toJSON = mongoose.Document::toJSON
mongoose.Document::toJSON = ->
    json = @_toJSON()

    json.id = @id

    delete json._id
    delete json.__v

    # Don't leak password hashes
    if json.passwordHash then delete json.passwordHash

    # Don't leak emails
    if json.email then delete json.email

    return json

# Connect to the database
exports.connect = (dbUrl, done) ->
    mongoose.connect dbUrl

    mongoose.connection.on 'error', console.error.bind(console, 'connection error: ')
    mongoose.connection.once 'open', ->
        done?()

# Close the database connection
exports.close = (done) ->
    mongoose.connection.close done
