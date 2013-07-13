jsonGate = require 'json-gate'

Authorization = require '../models/authorization'
Client = require '../models/client'

authController = exports

listSchema = jsonGate.createSchema
    type: 'object'
    properties:
        clientId:
            type: 'string'
            required: true
        clientSecret:
            type: 'string'
            required: true

createSchema = jsonGate.createSchema
    type: 'object'
    properties:
        clientId:
            type: 'string'
            required: true
        clientSecret:
            type: 'string'
            required: true
        scopes:
            type: 'array'
            items:
                type: 'string'
            default: []

# Get the client, making sure it exists and the secrets match up
getClient = (key, secret, done) ->
    Client.findOne {key}, (err, client) ->
        if err then return done(err.toString(), 500)
        if not client then return done('Client not found', 401)
        if client.secret isnt secret then return done('Invalid client secret', 401)

        done(null, client)

authController.list = (req, res) ->
    listSchema.validate req.query, (err, data) ->
        if err then return res.send(400, err.toString())

        getClient data.clientId, data.clientSecret, (err, client) ->
            if err then return res.send(client, err)

            params =
                clientId: data.clientId
                userId: req.user.id

            Authorization.find params, (err, auths) ->
                if err then return res.send(500, err.toString())

                res.json auths

authController.create = (req, res) ->
    createSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        getClient data.clientId, data.clientSecret, (err, client) ->
            if err then return res.send(client, err)

            auth = new Authorization
                userId: req.user.id
                clientId: data.clientId
                scopes: data.scopes

            auth.save (err, auth) ->
                if err then return res.send(500, err.toString())

                res.json 201, auth
