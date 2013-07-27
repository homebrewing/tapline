mongoose = require 'mongoose'
util = require '../util'

try
    bcrypt = require 'bcrypt'
catch err
    bcrypt = require 'bcryptjs'

UserSchema = new mongoose.Schema
    # Wether the user's email is confirmed
    confirmed:
        type: Boolean
        default: false
    # Registered email address
    email:
        type: String
        required: true
        lowercase: true
    # Displayed user name
    name:
        type: String
        required: true
        unique: true
        lowercase: true
    # An image URL template
    image:
        type: String
    # Hashed password
    passwordHash:
        type: String
        required: true
    # Creation date
    created:
        type: Date
        default: Date.now
    # List of user IDs being followed
    following:
        type: Array
        maxItems: 100
        items:
            type: mongoose.Schema.Types.ObjectId
    # Cached number of recipes owned
    recipeCount:
        type: Number
        default: 0

UserSchema.methods =
    # Authenticate a user, taking a password and a function (err, authenticated)
    # which will be called with authenticated=true if the password is correct.
    authenticate: (password, done) ->
        #if not @confirmed then return done('Unconfirmed email address!', false)

        bcrypt.compare password, @passwordHash, (err, res) =>
            if err then return done(err, false)
            done(null, res)

    # Set a new password using asyncronous bcrypt. The `done` function is
    # optional and called after the new hash has been set. This function does
    # NOT save the model.
    setPassword: (password, done) ->
        util.genPasswordHash password, (err, hash) =>
            if err then return done?(err)

            @passwordHash = hash
            done?()

module.exports = mongoose.model 'User', UserSchema
