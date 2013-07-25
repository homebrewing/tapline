Authorization = require '../../models/authorization'
Client = require '../../models/client'
Grant = require '../../models/grant'

oauthController = module.exports

oauthController.getAuthorization = (req, res) ->
    # TODO: check parameters
    scopes = (req.query.scope or '').split ','

    Grant.findOne userId: req.user.id, clientId: req.query.client_id, (err, grant) ->
        if err then return res.send(500, err.toString())

        # TODO: Compare grant scopes - user may need to reauthorize new scopes

        if grant
            res.redirect "#{req.query.redirect_uri}?code=#{grant.code}&state=#{req.query.state}"
        else
            Client.findOne _id: req.query.client_id, (err, client) ->
                if err then return res.send(500, err.toString())
                if not client then return res.send(404, 'Cannot find client')

                # If this is a trusted client then create the grant and authorization
                # without asking the user. This lets official apps magically work.
                if client.trusted
                    grant = new Grant
                        userId: req.user.id
                        clientId: client.id
                        scopes: scopes

                    grant.save (err) ->
                        if err then return res.send(500, err.toString())
                        res.redirect "#{req.query.redirect_uri}?code=#{grant.code}&state=#{req.query.state}"
                else
                    scopeMap =
                        'Public user account information': [
                            'permission-read',
                            scopes.indexOf('user') isnt -1 and 'permission-write' or '',
                            scopes.indexOf('user:delete') isnt -1 and 'permission-delete' or ''
                        ]
                        'Public user actions': [
                            'permission-read',
                            (scopes.indexOf('user') isnt -1 or scopes.indexOf('recipe') isnt -1) and 'permission-write' or '',
                            ''
                        ]
                        'Public recipes': [
                            'permission-read',
                            scopes.indexOf('recipe') isnt -1 and 'permission-write' or '',
                            scopes.indexOf('recipe:delete') isnt -1 and 'permission-delete' or ''
                        ]
                        'Public brews': [
                            'permission-read',
                            scopes.indexOf('recipe') isnt -1 and 'permission-write' or '',
                            scopes.indexOf('recipe:delete') isnt -1 and 'permission-delete' or ''
                        ]
                        'Private account email': [
                            scopes.indexOf('user:email') isnt -1 and 'permission-read',
                            '',
                            ''
                        ]
                        'Private actions & recipes': [
                            scopes.indexOf('private') isnt -1 and 'permission-read' or '',
                            scopes.indexOf('private') isnt -1 and 'permission-write' or '',
                            scopes.indexOf('private') isnt -1 and 'permission-delete' or ''
                        ]

                    res.render 'authorize',
                        clientId: client.id
                        clientName: client.name
                        clientDescription: client.description
                        scopeMap: scopeMap
                        scopes: scopes
                        state: req.query.state
                        redirectUri: req.query.redirect_uri

oauthController.postAuthorization = (req, res) ->
    # TODO: Check parameters
    Client.findOne _id: req.body.clientId, (err, client) ->
        if err then return res.send(500, err.toString())
        if not client then return res.send(404, 'Cannot find client')

        grant = new Grant
            clientId: client.id
            userId: req.user.id
            scopes: req.body.scopes.split ','

        grant.save (err, grant) ->
            if err then return res.send(500, err.toString())
            res.redirect "#{req.body.redirectUri}?code=#{grant.code}&state=#{req.body.state}"

oauthController.postAccessToken = (req, res) ->
    # TODO: Check parameters

    # Get and verify the client is who he says he is
    Client.findOne _id: req.body.clientId, (err, client) ->
        if err then return res.send(500, err.toString())
        if not client then return res.send(404, 'Cannot find client')

        # Valid requests must include the client secret
        if client.secret isnt req.body.clientSecret
            return res.send(401, 'Invalid client secret')

        # Make sure the grant exists and is valid
        Grant.findOne code: req.body.code, (err, grant) ->
            if err then return res.send(500, err.toString())
            if not grant then return res.send(404, 'Cannot find grant')

            if grant.clientId isnt client.id or grant.userId isnt req.user.id
                return res.send(401, 'Grant does not match client or user ID')

            # Create the oauth token!
            token = new Authorization
                userId: req.user.id
                clientId: client.id
                scopes: grant.scopes

            token.save (err, token) ->
                if err then return res.send(500, err.toString())

                res.json
                    access_token: token.code
                    token_type: 'bearer'
