crypto = require 'crypto'
mongoose = require 'mongoose'

GrantSchema = new mongoose.Schema
    userId:
        type: mongoose.Schema.Types.ObjectId
    clientId:
        type: mongoose.Schema.Types.ObjectId
    code:
        type: String
        unique: true
        default: ->
            crypto.randomBytes(20).toString 'hex'
    scopes:
        type: [String]

module.exports = mongoose.model 'Grant', GrantSchema
