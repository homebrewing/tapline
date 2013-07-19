crypto = require 'crypto'
mongoose = require 'mongoose'

AuthorizationSchema = new mongoose.Schema
    token:
        type: String
        unique: true
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

module.exports = mongoose.model 'Authorization', AuthorizationSchema
