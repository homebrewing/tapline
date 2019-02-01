brauhaus = require 'brauhaus'
jsonGate = require 'json-gate'
util = require '../../util'

durationConvertController = exports

# Duration convertion request schema
durationSchema = jsonGate.createSchema
    type: 'object'
    properties:
        values:
            type: 'array'
            minItems: 1
            maxItems: 25
            required: true
            items:
                type: ['string', 'number']
                min: 0
        outputFormat:
            type: 'string'
            enum: ['minutes', 'display']
            default: 'minutes'
        approximate:
            type: ['null', 'number']
            default: null

# Convert a duration in a number of minutes or as a human-readable
# representation into either a number of minutes or a display duration.
durationConvertController.convert = (req, res) ->
    durationSchema.validate req.body, (err, data) ->
        if err then return res.status(400).send(err.toString())

        values = (brauhaus.parseDuration value for value in data.values)

        converted = switch data.outputFormat
            when 'minutes'
                values
            when 'display'
                (brauhaus.displayDuration(value, data.approximate) for value in values)

        res.json
            format: data.outputFormat
            values: converted
