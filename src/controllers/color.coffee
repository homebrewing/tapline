brauhaus = require 'brauhaus'
jsonGate = require 'json-gate'
util = require '../util'

colorController = exports

# Color conversion request schema
convertSchema = jsonGate.createSchema
    type: 'object'
    properties:
        format:
            type: 'string'
            enum: ['srm', 'ebc', 'lovibond']
            required: true
        value:
            type: ['number', 'string']
            minimum: 0
            pattern: '^[\\d]+\\.?[\\d]*$'
            required: true
        outputFormat:
            type: 'string'
            enum: ['srm', 'ebc', 'lovibond', 'name', 'rgb', 'css']
            default: 'ebc'

# Convert a color value given as SRM, EBC, or Lovibond into one of the
# following: SRM, EBC, Lovibond, color name, RGB, or CSS string
colorController.convert = (req, res) ->
    params = util.extend {}, req.query, req.body

    convertSchema.validate params, (err, data) ->
        if err then return res.send(400, err.toString())

        srm = switch data.format
            when 'srm'
                data.value
            when 'ebc'
                brauhaus.ebcToSrm data.value
            when 'lovibond'
                brauhaus.lovibondToSrm data.value

        output = switch data.outputFormat
            when 'srm' then srm
            when 'ebc' then brauhaus.srmToEbc srm
            when 'lovibond' then brauhaus.srmToLovibond srm
            when 'name' then brauhaus.srmToName srm
            when 'rgb' then brauhaus.srmToRgb srm
            when 'css' then brauhaus.srmToCss srm

        if output is undefined
            return res.send(400, "Invalid output format '#{data.outputFormat}!")

        req.info "Converted color from #{data.format} to #{data.outputFormat}"

        res.json
            format: data.outputFormat
            value: output
