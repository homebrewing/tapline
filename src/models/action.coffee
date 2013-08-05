mongoose = require 'mongoose'
util = require '../util'

ActionSchema = new mongoose.Schema
    userId:
        type: mongoose.Schema.Types.ObjectId
        required: true
    created:
        type: Date
        default: Date.now
    type:
        type: String
        required: true
        enum: ['user-joined', 'user-followed', 'recipe-created']
    targetId:
        type: mongoose.Schema.Types.ObjectId
    private:
        type: Boolean
        default: false
    data:
        type: mongoose.Schema.Types.Mixed

module.exports = mongoose.model 'Action', ActionSchema
