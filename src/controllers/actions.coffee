jsonGate = require 'json-gate'
util = require '../util'

Action = require '../models/action'

actionsController = exports

# Action list request schema
listSchema = jsonGate.createSchema
    type: 'object'
    properties:
        userIds:
            type: 'array'
            minItems: 1
            maxItems: 60
            items:
                type: 'string'
        ids:
            type: 'array'
            minItems: 1
            maxItems: 60
            items:
                type: 'string'
        showPrivate:
            type: 'string'
            enum: ['true', 'false']
            default: 'true'
        offset:
            type: 'number'
            default: 0
        limit:
            type: 'number'
            default: 20
            max: 60
        sort:
            type: 'string'
            enum: ['created', '-created']
            default: '-created'

actionsController.list = (req, res) ->
    if req.params.id
        req.query.ids = req.params.id

    util.queryConvert req.query, {userIds: Array, ids: Array, offset: Number, limit: Number}, (err) ->
        if err then return res.send(400, err.toString())

        listSchema.validate req.query, (err, data) ->
            if err then return res.send(400, err.toString())

            query =
                $or: [
                    {private: false}
                ]

            if data.showPrivate is 'true'
                query.$or.push {private: true, userId: req.user.id}

            if data.userIds then query.$or[0].userId =
                $in: data.userIds
            else if data.ids then query.$or[0]._id =
                $in: data.ids

            Action.find(query).sort(data.sort).skip(data.offset).limit(data.limit).exec (err, actions) ->
                if err then return res.send(500, err.toString())
                res.json actions