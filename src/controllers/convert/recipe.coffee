brauhaus = require 'brauhaus'
jsonGate = require 'json-gate'
util = require '../../util'

require 'brauhaus-beerxml'

recipeController = exports

recipeSchema = jsonGate.createSchema
    type: 'object'
    properties:
        format:
            type: 'string'
            required: true
            enum: ['json', 'beerxml']
        recipes: util.recipeListSchema
        outputFormat:
            type: 'string'
            default: 'json'
            enum: ['json', 'beerxml']

# Convert a passed-in recipe from and to JSON / BeerXML
recipeController.convert = (req, res) ->
    recipeSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        recipes = util.getRecipeList data.format, data.recipes

        switch data.outputFormat
            when 'beerxml'
                recipes = (recipe.toBeerXml() for recipe in recipes)

        res.json
            format: data.outputFormat
            recipes: recipes
