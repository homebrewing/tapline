mongoose = require 'mongoose'
slug = require 'slug'
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
    # External ID, e.g. Google ID or Facebook ID
    externalId:
        type: String
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
    location:
        type: mongoose.Schema.Types.Mixed
        # Default is Seattle, WA
        default: [122.3331, 47.6097]
        index: '2dsphere'
    # Cached number of recipes owned
    recipeCount:
        type: Number
        default: 0

UserSchema.statics =
    # Get or create a new user from a third-party social service
    findOrCreateExternal: (externalId, profile, done) ->
        User.findOne {externalId}, (err, user) ->
            if err then return done(err)
            if user then return done(null, user)

            # Create a new user
            user = new User
                name: slug(profile.displayName).toLowerCase()
                email: profile.emails[0].value
                externalId: externalId
                image: profile.photos[0].value

            user.save (err, saved) ->
                if err then return done(err)

                # TODO: Pick another name if it's taken...

                done null, saved

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

module.exports = User = mongoose.model 'User', UserSchema
