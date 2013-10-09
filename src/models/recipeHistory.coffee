mongoose = require 'mongoose'
util = require '../util'

RecipeHistorySchema = new mongoose.Schema
    recipe:
        type: mongoose.Schema.Types.ObjectId
        required: true
        ref: 'Recipe'
    entries:
        type: Array
        items:
            type: Object

module.exports = mongoose.model 'RecipeHistory', RecipeHistorySchema
