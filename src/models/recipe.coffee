brauhaus = require 'brauhaus'
mongoose = require 'mongoose'
util = require '../util'

RecipeSchema = new mongoose.Schema
    user:
        type: mongoose.Schema.Types.ObjectId
        required: true
        ref: 'User'
    created:
        type: Date
        default: Date.now
    modified:
        type: Date
        default: Date.now
    name:
        type: String
    slug:
        type: String
    og:
        type: Number
    fg:
        type: Number
    ibu:
        type: Number
    abv:
        type: Number
    color:
        type: Number
    private:
        type: Boolean
        default: false
    grade:
        type: Number
        default: 0.0
    data:
        type: mongoose.Schema.Types.Mixed

module.exports = mongoose.model 'Recipe', RecipeSchema
