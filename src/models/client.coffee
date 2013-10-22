crypto = require 'crypto'
mongoose = require 'mongoose'

ClientSchema = new mongoose.Schema
    userId:
        type: mongoose.Schema.Types.ObjectId
        required: true
    name:
        type: String
    description:
        type: String
    imageUrl:
        type: String
    secret:
        type: String
        default: ->
            crypto.randomBytes(20).toString 'hex'
    redirectUri:
        type: Array
        items:
            type: String
    created:
        type: Date
        default: Date.now
    trusted:
        type: Boolean
        default: false

module.exports = mongoose.model 'Client', ClientSchema
