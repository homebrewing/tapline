_ = require 'lodash'
gravatar = require 'gravatar'
jsonGate = require 'json-gate'
util = require '../util'

Action = require '../models/action'
User = require '../models/user'

userController = exports

USERNAME_RE = '^[a-z0-9_-]{4,30}$'

# User list request schema
listSchema = jsonGate.createSchema
    type: 'object'
    properties:
        ids:
            type: 'array'
            minItems: 0
            maxItems: 60
            items:
                type: 'string'
        names:
            type: 'array'
            minItems: 0
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
            enum: ['name', '-name', 'created', '-created', 'location',
                   'recipeCount', '-recipeCount']
            default: 'name'
        # If sort is location, this optionally sets the long/lat point
        # which defaults to the current user's location if not set.
        fromLong:
            type: 'number'
        fromLat:
            type: 'number'

# User creation request schema
creationSchema = jsonGate.createSchema
    type: 'object'
    properties:
        email:
            type: 'string'
            format: 'email'
            required: true
        name:
            type: 'string'
            required: true
            pattern: USERNAME_RE
        image:
            type: 'string'
        password:
            type: 'string'
            required: true
        following:
            type: 'array'
            maxItems: 100
            items:
                type: 'string'
        location:
            type: 'array'
            minItems: 2
            maxItems: 2
            items:
                type: 'number'

# User update request schema
updateSchema = jsonGate.createSchema
    type: 'object'
    properties:
        id:
            type: 'string'
            required: true
        email:
            type: 'string'
            format: 'email'
        name:
            type: 'string'
            pattern: USERNAME_RE
        image:
            type: 'string'
        password:
            type: 'string'
        following:
            type: 'array'
            maxItems: 100
            items:
                type: 'string'
        addFollowing:
            type: 'array'
            maxItems: 100
            items:
                type: 'string'
        removeFollowing:
            type: 'array'
            maxItems: 100
            items:
                type: 'string'
        location:
            type: 'array'
            minItems: 2
            maxItems: 2
            items:
                type: 'number'

# User deletion request schema
deleteSchema = jsonGate.createSchema
    type: 'object'
    properties:
        id:
            type: 'string'
            required: true

userController.list = (req, res) ->
    if req.params.id
        req.query.ids = req.params.id

    conversions =
        ids: Array
        names: Array
        offset: Number
        limit: Number
        fromLong: Number
        fromLat: Number

    util.queryConvert req.query, conversions, (err) ->
        if err then return res.status(400).send(err.toString())

        listSchema.validate req.query, (err, data) ->
            if err then return res.status(400).send(err.toString())

            select = {}

            if data.ids then select._id =
                $in: data.ids

            if data.names then select.name =
                $in: data.names

            if data.sort is 'location'
                if req.user
                    coords = req.user.location
                else
                    coords = [0, 0]

                if data.fromLong
                    coords = [data.fromLong, coords[1]]
                if data.fromLat
                    coords = [coords[0], data.fromLat]

                select.location =
                    $near:
                        type: 'Point'
                        coordinates: coords

            query = User.find(select)

            if data.sort isnt 'location'
                query = query.sort(data.sort)

            query.skip(data.offset).limit(data.limit).exec (err, users) ->
                if err then return res.status(500).send(err.toString())
                res.json users

userController.profile = (req, res) ->
    profile =
        id: req.user.id
        name: req.user.name
        image: req.user.image

    if req.authInfo?.scopes?.indexOf('user:email') isnt -1
        profile.email = req.user.email

    res.json profile

userController.create = (req, res) ->
    creationSchema.validate req.body, (err, data) ->
        if err then return res.status(400).send(err.toString())

        u = new User
            name: data.name
            email: data.email
            following: data.following
            image: data.image or gravatar.url data.email, {s: 'SIZE', d: 'retro'}
            location: data.location

        u.setPassword data.password, (err) ->
            if err then return res.status(500).send(err.toString())
            u.save (err, saved) ->
                if err and err.code is util.ERROR_DB_DUPE
                    return res.status(400).send("User name #{data.name} already taken!")
                if err then return res.status(500).send(err.toString())

                action = new Action
                    user: saved._id
                    type: 'user-joined'
                    data:
                        name: saved.name
                        image: saved.image

                action.save()

                res.status(201).json(saved)

userController.update = (req, res) ->
    params = util.extend {}, req.params, req.body
    updateSchema.validate params, (err, data) ->
        if err then return res.status(400).send(err.toString())

        if req.user.id isnt data.id
            return res.status(401).send("Token does not match user ID")

        count = [data.following, data.addFollowing, data.removeFollowing].filter((x) -> x).length

        if count > 1
            return res.status(400).send('Only one of following, addFollowing or removeFollowing can be given')

        # Update the user with a find-and-update. This is called
        # below based on whether a password needs to be updated.
        updateFunc = (passwordHash) ->
            update = {}

            if data.email then update.email = data.email
            if data.name then update.name = data.name
            if data.image then update.image = data.image

            if passwordHash then update.passwordHash = passwordHash

            if data.following then update.following = data.following
            if data.addFollowing then update.$addToSet = {following: {$each: data.addFollowing, $slice: 100}}
            if data.removeFollowing then update.$pullAll = {following: data.removeFollowing}

            if data.location then update.location = data.location

            User.findByIdAndUpdate data.id, update, (err, saved) ->
                if err and err.code is util.ERROR_DB_DUPE
                    return res.status(400).send("User name #{data.name} already taken!")
                if err then return res.status(500).send(err.toString())
                if not saved then return res.status(404).send("User not found")

                # Create user-followed actions if new users were followed
                for added in _.without.apply(this, [saved.following].concat(req.user.following))
                    User.findById added, (err, addedUser) ->
                        if err then req.error(err.toString())

                        if addedUser
                            action = new Action
                                user: saved._id
                                type: 'user-followed'
                                targetId: addedUser.id
                                data:
                                    name: addedUser.name
                                    image: addedUser.image

                            action.save()

                res.json saved

        if data.password
            util.genPasswordHash data.password, (err, hash) ->
                updateFunc hash
        else
            updateFunc()

userController.delete = (req, res) ->
    params = util.extend {}, req.params
    deleteSchema.validate params, (err, data) ->
        if err then return res.status(400).send(err.toString())

        if req.user.id isnt data.id
            return res.status(401).send("Token does not match user ID")

        User.findByIdAndRemove data.id, (err) ->
            if err then return res.status(500).send(err.toString())

            # TODO: Decide if this should remove actions/recipes/brews/etc

            res.status(204).send(null)
