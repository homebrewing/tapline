brauhaus = require 'brauhaus'
jsonGate = require 'json-gate'

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
            type: 'number'
            minimum: 0
            required: true

# Convert a color value given as SRM, EBC, or Lovibond into one of the
# following: SRM, EBC, Lovibond, color name, RGB, or CSS string
colorController.convert = (req, res) ->
    convertSchema.validate req.body, (err, data) ->
        if err then return res.send(400, err.toString())

        srm = switch data.format
            when 'srm'
                data.value
            when 'ebc'
                brauhaus.ebcToSrm data.value
            when 'lovibond'
                brauhaus.lovibondToSrm data.value

        output = switch req.params.format
            when 'srm' then srm
            when 'ebc' then brauhaus.srmToEbc srm
            when 'lovibond' then brauhaus.srmToLovibond srm
            when 'name' then brauhaus.srmToName srm
            when 'rgb' then brauhaus.srmToRgb srm
            when 'css' then brauhaus.srmToCss srm

        if output is undefined
            return res.send(400, "Invalid output format '#{req.params.format}!")

        req.info "Converted color from #{data.format} to #{req.params.format}"

        res.json
            format: req.params.format
            value: output
