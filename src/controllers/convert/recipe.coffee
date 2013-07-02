brauhaus = require 'brauhaus'
jsonGate = require 'json-gate'

require 'brauhaus-beerxml'

recipeController = exports

recipeSchema = jsonGate.createSchema
    type: 'object'
    properties:
        format:
            type: 'string'
            required: true
            enum: ['json', 'beerxml']
        recipes:
            type: 'array'
            required: true
            minItems: 1
            maxItems: 10
            items:
                type: ['object', 'string']
        outputFormat:
            type: 'string'
            default: 'json'
            enum: ['json', 'beerxml']

# Convert a passed-in recipe from and to JSON / BeerXML
recipeController.convert = (req, res) ->
    recipeSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        recipes = switch data.format
            when 'json' then (new brauhaus.Recipe(recipe) for recipe in data.recipes)
            when 'beerxml'
                temp = []
                for xml in data.recipes
                    temp = temp.concat brauhaus.Recipe.fromBeerXml(xml)

        switch data.outputFormat
            when 'beerxml'
                recipes = (recipe.toBeerXml() for recipe in recipes)

        res.json
            format: data.outputFormat
            recipes: recipes
