brauhaus = require 'brauhaus'

require 'brauhaus-beerxml'

# Extend an object with the values of other objects
exports.extend = (objects...) ->
    original = objects[0]
    for object in objects[1..]
        for own key, value of object
            original[key] = value
    return original

# A JSON-schema for a list of recipes as JSON or BeerXML
exports.recipeListSchema =
    type: 'array'
    required: true
    minItems: 1
    maxItems: 10
    items:
        type: ['object', 'string']

# Get a list of Brauhaus recipe objects from an input format (e.g. json)
# and a list of recipe data from the above recipe list schema.
exports.getRecipeList = (format, list) ->
    switch format
        when 'json' then (new brauhaus.Recipe(recipe) for recipe in list)
        when 'beerxml'
            temp = []
            for xml in list
                temp = temp.concat brauhaus.Recipe.fromBeerXml(xml)
            temp
