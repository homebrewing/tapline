brauhaus = require 'brauhaus'
jsonGate = require 'json-gate'
util = require '../../util'

colorController = exports

# Color conversion request schema
convertSchema = jsonGate.createSchema
    type: 'object'
    properties:
        format:
            type: 'string'
            enum: ['srm', 'ebc', 'lovibond']
            required: true
        values:
            type: 'array'
            minItems: 1
            maxItems: 25
            required: true
            items:
                type: 'number'
                minimum: 0
                required: true
        outputFormat:
            type: 'string'
            enum: ['srm', 'ebc', 'lovibond', 'name', 'rgb', 'css']
            default: 'ebc'

# Convert a color value given as SRM, EBC, or Lovibond into one of the
# following: SRM, EBC, Lovibond, color name, RGB, or CSS string
colorController.convert = (req, res) ->
    convertSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        srm = switch data.format
            when 'srm'
                data.values
            when 'ebc'
                (brauhaus.ebcToSrm value for value in data.values)
            when 'lovibond'
                (brauhaus.lovibondToSrm value for value in data.values)

        output = switch data.outputFormat
            when 'srm' then srm
            when 'ebc' then (brauhaus.srmToEbc value for value in srm)
            when 'lovibond' then (brauhaus.srmToLovibond value for value in srm)
            when 'name' then (brauhaus.srmToName value for value in srm)
            when 'rgb' then (brauhaus.srmToRgb value for value in srm)
            when 'css' then (brauhaus.srmToCss value for value in srm)

        if output is undefined
            return res.send(400, "Invalid output format '#{data.outputFormat}!")

        req.info "Converted color(s) from #{data.format} to #{data.outputFormat}"

        res.json
            format: data.outputFormat
            values: output
