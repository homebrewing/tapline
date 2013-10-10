_ = require 'lodash'
brauhaus = require 'brauhaus'
jsonGate = require 'json-gate'
util = require '../util'

Action = require '../models/action'
Recipe = require '../models/recipe'
RecipeHistory = require '../models/recipeHistory'

require 'brauhaus-diff'

recipeController = exports

# Recipe list request schema
listSchema = jsonGate.createSchema
    type: 'object'
    properties:
        ids:
            type: 'array'
            minItems: 1
            maxItems: 60
            items:
                type: 'string'
        offset:
            type: 'number'
            default: 0
        limit:
            type: 'number'
            default: 20
            max: 60
        sort:
            type: 'string'
            enum: ['name', '-name', 'created', '-created']
            default: 'name'
        detail:
            type: 'boolean'
            default: false
        showPrivate:
            type: 'boolean'
            default: false

# Recipe creation request schema
# Takes in any valid Brauhaus.Recipe constructor values
creationSchema = jsonGate.createSchema
    type: 'object'
    properties:
        private:
            type: 'boolean'
            default: false
        detail:
            type: 'boolean'
            default: false
        recipe:
            type: 'any'

updateSchema = jsonGate.createSchema
    type: 'object'
    properties:
        id:
            type: 'string'
            required: true
        private:
            type: 'boolean'
        detail:
            type: 'boolean'
            default: false
        recipe:
            type: 'any'

# Serialize a recipe for a JSON response
recipeController.serialize = (recipe, detail) ->
    r = new brauhaus.Recipe(recipe.data)

    recipeData =
        agingDays: r.agingDays
        agingTemp: r.agingTemp
        agingTempF: brauhaus.cToF r.agingTemp
        author: r.author
        batchSize: r.batchSize
        batchSizeGallons: brauhaus.litersToGallons r.batchSize
        boilSize: r.boilSize
        boilSizeGallons: brauhaus.litersToGallons r.boilSize
        bottlingPressure: r.bottlingPressure
        bottlingTemp: r.bottlingTemp
        bottlingTempF: brauhaus.cToF r.bottlingTemp
        description: r.description
        fermentables: r.fermentables
        ibuMethod: r.ibuMethod
        mash: r.mash
        mashEfficiency: r.mashEfficiency
        name: r.name
        primaryDays: r.primaryDays
        primaryTemp: r.primaryTemp
        primaryTempF: brauhaus.cToF r.primaryTemp
        secondaryDays: r.secondaryDays
        secondaryTemp: r.secondaryTemp
        secondaryTempF: brauhaus.cToF r.secondaryTemp
        servingSize: r.servingSize
        servingSizeOz: brauhaus.litersToGallons r.servingSize
        spices: r.spices
        steepEfficiency: r.steepEfficiency
        steepTime: r.steepTime
        style: r.style
        tertiaryDays: r.tertiaryDays
        tertiaryTemp: r.tertiaryTemp
        tertiaryTempF: brauhaus.cToF r.tertiaryTemp
        yeast: r.yeast

    if detail
        r.calculate()

        _.extend recipeData,
            abv: r.abv
            abw: r.abw
            brewDayDuration: r.brewDayDuration
            buToGu: r.buToGu
            bv: r.bv
            calories: r.calories
            color: r.color
            colorEbc: brauhaus.srmToEbc r.color
            colorLovibond: brauhaus.srmToLovibond r.color
            fg: r.fg
            fgPlato: r.fgPlato
            ibu: r.ibu
            og: r.og
            ogPlato: r.ogPlato
            price: r.price
            realExtract: r.realExtract
            timeline: r.timeline()
            timelineImperial: r.timeline false

    serialized =
        id: recipe.id
        user: recipe.user
        created: recipe.created
        private: recipe.private
        data: recipeData

recipeController.list = (req, res) ->
    if req.params.id
        req.query.ids = req.params.id

    conversions =
        ids: Array
        offset: Number
        limit: Number
        detail: Boolean
        showPrivate: Boolean

    util.queryConvert req.query, conversions, (err) ->
        if err then return res.send(400, err.toString())

        listSchema.validate req.query, (err, data) ->
            if err then return res.send(400, err.toString())

            select =
                $or: [
                    {private: false}
                ]

            if data.showPrivate
                if not req.user or req.authInfo?.scopes?.indexOf('private') is -1
                    return res.send(401, 'Scope "private" required to view private recipes!')
                select.$or.push {private: true, user: req.user._id}

            if data.ids then select._id =
                $in: data.ids

            query = Recipe.find select

            query = query.sort data.sort

            query = query.populate 'user', '_id name image'

            query.skip(data.offset).limit(data.limit).exec (err, recipes) ->
                if err then return res.send(500, err.toString())

                responses = for recipe in recipes
                    recipeController.serialize recipe, data.detail

                res.json responses

recipeController.create = (req, res) ->
    creationSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        data.recipe.author ?= req.user.name

        recipeData = new brauhaus.Recipe(data.recipe)

        recipeData.calculate()

        recipe = new Recipe
            user: req.user
            name: recipeData.name
            og: recipeData.og
            fg: recipeData.fg
            ibu: recipeData.ibu
            abv: recipeData.abv
            color: recipeData.color
            private: data.private
            data: recipeData.toJSON()

        recipe.save (err, saved) ->
            if err then return res.send(500, err.toString())

            # Create user action
            action = new Action
                user: req.user._id
                type: 'recipe-created'
                targetId: saved.id
                private: recipe.private
                data:
                    name: recipe.name
                    description: recipe.description
                    og: recipeData.og
                    fg: recipeData.fg
                    ibu: recipeData.ibu
                    abv: recipeData.abv
                    color: recipeData.color

            action.save()

            res.json recipeController.serialize(saved, data.detail)

recipeController.update = (req, res) ->
    params = _.extend {}, req.params, req.body
    updateSchema.validate params, (err, data) ->
        if err then return res.send(400, err.toString())

        update =
            modified: Date.now()

        if data.private then update.private = data.private
        if data.recipe
            recipe = new brauhaus.Recipe(data.recipe)
            recipe.calculate()
            recipe.timeline()

            update.name = recipe.name
            update.og = recipe.og
            update.fg = recipe.fg
            update.ibu = recipe.ibu
            update.abv = recipe.abv
            update.color = recipe.color
            update.data = recipe

            #req.info(require('util').inspect(update))

        Recipe.findById data.id, (err, original) ->
            if err then return res.send(500, err.toString())
            if not original then return res.send(404, 'Recipe not found')

            if data.recipe
                # Generate a diff of the old vs. new recipe
                diff = brauhaus.Diff.diff(new brauhaus.Recipe(original.data).toJSON(), recipe.toJSON())
                if Object.keys(diff).length
                    # TODO: Should this be replaced with an atomic action that
                    # upserts to create the entry when needed???
                    RecipeHistory.findOne recipe: original.id, (err, history) ->
                        if err then return req.error(err)

                        if not history
                            history = new RecipeHistory
                                recipe: original.id

                        history.entries ?= []
                        history.entries.push
                            date: Date.now()
                            diff: diff

                        history.save (err) ->
                            if err then console.log err

            Recipe.findByIdAndUpdate data.id, update, (err, saved) ->
                if err then return res.send(500, err.toString())

                res.json recipeController.serialize(saved, data.detail)
