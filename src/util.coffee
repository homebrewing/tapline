brauhaus = require 'brauhaus'

require 'brauhaus-beerxml'

try
    bcrypt = require 'bcrypt'
catch err
    bcrypt = require 'bcryptjs'

# Test database URL
exports.testDb = 'mongodb://localhost/tapline_test'

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

# Convert a list of parameters on an object to integers, useful for
# pre-processing `req.query` which sends everything as a string before
# validating with JSON Schema. Calls `done` when finished or when
# the first error is encountered.
exports.toInt = (obj, params, done) ->
    for param in params
        if obj[param] is undefined
            continue

        if isNaN(obj[param])
            return done("#{param} value '#{obj[param]}' could not be converted to an integer!")

        obj[param] = parseInt obj[param]

    done()

# Asyncronously generate a secure password hash
exports.genPasswordHash = (password, done) ->
    bcrypt.genSalt 10, (err, salt) =>
        if err then return done(err)

        bcrypt.hash password, salt, (err, hash) =>
            if err then return done(err)

            done(null, hash)
