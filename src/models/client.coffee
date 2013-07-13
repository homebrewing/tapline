crypto = require 'crypto'
mongoose = require 'mongoose'

ClientSchema = new mongoose.Schema
    name:
        type: String
    key:
        type: String
        unique: true
        default: ->
            crypto.randomBytes(10).toString 'hex'
    secret:
        type: String
        default: ->
            crypto.randomBytes(20).toString 'hex'
    redirectUri:
        type: String
    created:
        type: Date
        default: Date.now

module.exports = mongoose.model 'Client', ClientSchema
