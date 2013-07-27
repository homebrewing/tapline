_ = require 'lodash'
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
            enum: ['name', '-name', 'created', '-created', 'recipeCount', '-recipeCount']
            default: 'name'

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
        password:
            type: 'string'
            required: true
        following:
            type: 'array'
            maxItems: 100
            items:
                type: 'string'

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

    util.queryConvert req.query, {ids: Array, offset: Number, limit: Number}, (err) ->
        if err then return res.send(400, err.toString())

        listSchema.validate req.query, (err, data) ->
            if err then return res.send(400, err.toString())

            query = {}

            if data.ids then query._id =
                $in: data.ids

            User.find(query).sort(data.sort).skip(data.offset).limit(data.limit).exec (err, users) ->
                if err then return res.send(500, err.toString())
                res.json users

userController.profile = (req, res) ->
    profile =
        id: req.user.id
        name: req.user.name

    if req.authInfo?.scopes?.indexOf('user:email') isnt -1
        profile.email = req.user.email

    res.json profile

userController.create = (req, res) ->
    creationSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        u = new User
            name: data.name
            email: data.email
            following: data.following

        u.setPassword data.password, (err) ->
            if err then return res.send(500, err.toString())
            u.save (err, saved) ->
                if err and err.code is util.ERROR_DB_DUPE
                    return res.send 400, "User name #{data.name} already taken!"
                if err then return res.send(500, err.toString())

                action = new Action
                    userId: saved.id
                    type: 'user-joined'
                    data:
                        name: saved.name

                action.save()

                res.json 201, saved

userController.update = (req, res) ->
    params = util.extend {}, req.params, req.body
    updateSchema.validate params, (err, data) ->
        if err then return res.send(400, err.toString())

        if req.user.id isnt data.id
            return res.send 401, "Token does not match user ID"

        count = [data.following, data.addFollowing, data.removeFollowing].filter((x) -> x).length

        if count > 1
            return res.send(400, 'Only one of following, addFollowing or removeFollowing can be given')

        # Update the user with a find-and-update. This is called
        # below based on whether a password needs to be updated.
        updateFunc = (passwordHash) ->
            update = {}

            if data.email then update.email = data.email
            if data.name then update.name = data.name

            if passwordHash then update.passwordHash = passwordHash

            if data.following then update.following = data.following
            if data.addFollowing then update.$addToSet = {following: {$each: data.addFollowing, $slice: 100}}
            if data.removeFollowing then update.$pullAll = {following: data.removeFollowing}

            User.findByIdAndUpdate data.id, update, (err, saved) ->
                if err and err.code is util.ERROR_DB_DUPE
                    return res.send 400, "User name #{data.name} already taken!"
                if err then return res.send(500, err.toString())
                if not saved then return res.send(404, "User not found")

                # Create user-followed actions if new users were followed
                for added in _.without.apply(this, [saved.following].concat(req.user.following))
                    User.findById added, (err, addedUser) ->
                        if err then req.error(err.toString())

                        if addedUser
                            action = new Action
                                userId: saved.id
                                type: 'user-followed'
                                targetId: addedUser.id
                                data:
                                    name: addedUser.name

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
        if err then return res.send(400, err.toString())

        if req.user.id isnt data.id
            return res.send 401, "Token does not match user ID"

        User.findByIdAndRemove data.id, (err) ->
            if err then return res.send(500, err.toString())

            res.send 204, null
