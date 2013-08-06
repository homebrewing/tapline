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
            type: 'boolean'
            default: false
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

    conversions =
        userIds: Array
        ids: Array
        offset: Number
        limit: Number
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
                    return res.send(401, 'Scope "private" required to view private actions!')
                select.$or.push {private: true, userId: req.user.id}

            if data.userIds then select.$or[0].userId =
                $in: data.userIds
            else if data.ids then select.$or[0]._id =
                $in: data.ids

            query = Action.find(select).sort(data.sort).skip(data.offset).limit(data.limit)

            query = query.populate('user', '_id name image')

            query.exec (err, actions) ->
                if err then return res.send(500, err.toString())
                res.json actions
