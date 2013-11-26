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

# Make user+slug unique
RecipeSchema.index {user: 1, slug: 1}, {unique: true}

# Cover common queries
RecipeSchema.index {id: 1, user: 1, name: 1, created: -1, slug: 1, private: 1, grade: -1}

module.exports = mongoose.model 'Recipe', RecipeSchema
