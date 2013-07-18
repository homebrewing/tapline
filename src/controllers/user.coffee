jsonGate = require 'json-gate'
util = require '../util'

User = require '../models/user'

userController = exports

USERNAME_RE = '^[a-z0-9_-]{4,30}$'

# User list request schema
listSchema = jsonGate.createSchema
    type: 'object'
    properties:
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

# User deletion request schema
deleteSchema = jsonGate.createSchema
    type: 'object'
    properties:
        id:
            type: 'string'
            required: true

userController.list = (req, res) ->
    util.toInt req.query, ['offset', 'limit'], (err) ->
        if err then return res.send(400, err.toString())

        listSchema.validate req.query, (err, data) ->
            if err then return res.send(400, err.toString())

            User.find().skip(data.offset).limit(data.limit).sort(data.sort).exec (err, users) ->
                res.json
                    users: users

userController.create = (req, res) ->
    creationSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        u = new User
            name: data.name
            email: data.email

        u.setPassword data.password, (err) ->
            if err then return res.send(500, err.toString())
            u.save (err, saved) ->
                if err and err.code is util.ERROR_DB_DUPE
                    return res.send 400, "User name #{data.name} already taken!"
                if err then return res.send(500, err.toString())

                res.json 201, saved

userController.update = (req, res) ->
    params = util.extend {}, req.params, req.body
    updateSchema.validate params, (err, data) ->
        if err then return res.send(400, err.toString())

        if req.user.id isnt data.id
            return res.send 401, "Token does not match user ID"

        # Update the user with a find-and-update. This is called
        # below based on whether a password needs to be updated.
        updateFunc = (passwordHash) ->
            update = {}

            if data.email then update.email = data.email
            if data.name then update.name = data.name

            if passwordHash then update.passwordHash = passwordHash

            User.findByIdAndUpdate data.id, update, (err, saved) ->
                if err and err.code is util.ERROR_DB_DUPE
                    return res.send 400, "User name #{data.name} already taken!"
                if err then return res.send(500, err.toString())
                if not saved then return res.send(404, "User not found")

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
