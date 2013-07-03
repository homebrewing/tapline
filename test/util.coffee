assert = require 'assert'
brauhaus = require 'brauhaus'
sinon = require 'sinon'
util = require '../lib/util'

describe 'Extending objects', ->
    it 'Should contain properties from both objects', ->
        obj = util.extend {a: 1}, {b: 2}

        assert.equal 1, obj.a
        assert.equal 2, obj.b

describe 'Getting a list of recipes', ->
    inputFormatMap =
        'beerxml': ['fromBeerXml', '<recipes><recipe><name>foo</name></recipe></recipes>']

    for format, [method, recipe] of inputFormatMap
        do (format, method, recipe) ->
            describe "Input format '#{format}'", ->
                before ->
                    sinon.spy brauhaus.Recipe, method

                it "Should call Recipe.#{method}", ->
                    recipes = util.getRecipeList format, [recipe]
                    assert.ok brauhaus.Recipe[method].called

                after ->
                    brauhaus.Recipe[method].restore()
