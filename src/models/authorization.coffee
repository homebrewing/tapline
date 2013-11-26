crypto = require 'crypto'
mongoose = require 'mongoose'

AuthorizationSchema = new mongoose.Schema
    token:
        type: String
        unique: true
        index: 1
        default: ->
            crypto.randomBytes(20).toString 'hex'
    userId:
        type: mongoose.Schema.Types.ObjectId
        required: true
    clientId:
        type: mongoose.Schema.Types.ObjectId
        required: true
    scopes:
        type: [String]
    created:
        type: Date
        default: Date.now

# Cover common queries
AuthorizationSchema.index {userId: 1, clientId: 1}

module.exports = mongoose.model 'Authorization', AuthorizationSchema
