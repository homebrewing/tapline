brauhaus = require 'brauhaus'
jsonGate = require 'json-gate'
util = require '../../util'

require 'brauhaus-beerxml'

recipeController = exports

# Recipe calculation request schema
recipeSchema = jsonGate.createSchema
    type: 'object'
    properties:
        format:
            type: 'string'
            enum: ['json', 'beerxml']
        recipes: util.recipeListSchema
        siUnits:
            type: 'boolean'
            default: true

# Calculate important values about a recipe like OG, FG, IBU, ABV, etc
recipeController.calculate = (req, res) ->
    recipeSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        recipes = util.getRecipeList data.format, data.recipes
        
        responses = for recipe in recipes
            recipe.calculate()
            timeline = recipe.timeline(data.siUnits)
            {
                abv: recipe.abv
                abw: recipe.abw
                buToGu: recipe.buToGu
                bv: recipe.bv
                calories: recipe.calories
                color: recipe.color
                fg: recipe.fg
                fgPlato: recipe.fgPlato
                grainWeight: recipe.grainWeight()
                ibu: recipe.ibu
                og: recipe.og
                ogPlato: recipe.ogPlato
                price: recipe.price
                realExtract: recipe.realExtract
                timeline
            }

        res.json responses
