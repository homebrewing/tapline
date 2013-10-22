_ = require 'lodash'
Authorization = require '../../models/authorization'
Client = require '../../models/client'
Grant = require '../../models/grant'

oauthController = module.exports

redirectAllowed = (redirectUri, client) ->
    allowed = false

    for possible in client.redirectUri
        if redirectUri is possible
            allowed = true
            break

    return allowed

authFromGrant = (grant, done) ->
    Authorization.findOne userId: grant.userId, clientId: grant.clientId, (err, auth) ->
        if err then return done(err)
        if not auth
            # Create the oauth token!
            auth = new Authorization
                userId: grant.userId
                clientId: grant.clientId
                scopes: grant.scopes

            auth.save (err, auth) ->
                if err then return done(err)

                done null, auth
        else
            if _.isEqual(grant.scopes, auth.scopes)
                done null, auth
            else
                auth.scopes = grant.scopes

                auth.save (err, auth) ->
                    if err then return done(err)

                    done null, auth

oauthController.getAuthorization = (req, res) ->
    # TODO: check parameters
    scopes = (req.query.scope or '').split ','

    Grant.findOne userId: req.user.id, clientId: req.query.client_id, (err, grant) ->
        if err and err.name is 'CastError' then return res.send(404, 'Cannot find client')
        if err then return res.send(500, err.toString())

        # TODO: Compare grant scopes - user may need to reauthorize new scopes

        if grant
            switch req.query.type
                when 'web_server'
                    res.redirect "#{req.query.redirect_uri}?code=#{grant.code}&state=#{req.query.state}"
                when 'token'
                    Client.findOne _id: req.query.client_id, (err, client) ->
                        if redirectAllowed req.query.redirect_uri, client
                            authFromGrant grant, (err, auth) ->
                                if err then return res.send 500, err.toString()
                                res.redirect "#{req.query.redirect_uri}#access_token:#{auth.token}"
                        else
                            res.send 400, "Redirect not allowed: #{req.query.redirect_uri}"
                else
                    return res.send 400, "Invalid type #{req.query.type}"
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

                        switch req.query.type
                            when 'web_server'
                                res.redirect "#{req.query.redirect_uri}?code=#{grant.code}&state=#{req.query.state}"
                            when 'token'
                                if redirectAllowed req.query.redirect_uri, client
                                    authFromGrant grant, (err, auth) ->
                                        if err then return res.send 500, err.toString()
                                        res.redirect "#{req.query.redirect_uri}#access_token:#{auth.token}"
                                else
                                    res.send 400, "Redirect not allowed: #{req.query.redirect_uri}"
                            else
                                return res.send 400, "Invalid type #{req.query.type}"
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
                        type: req.query.type
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

            switch req.body.type
                when 'web_server'
                    res.redirect "#{req.body.redirectUri}?code=#{grant.code}&state=#{req.body.state}"
                when 'token'
                    if redirectAllowed req.body.redirectUri, client
                        authFromGrant grant, (err, auth) ->
                            if err then return res.send 500, err.toString()
                            res.redirect "#{req.body.redirectUri}#access_token:#{auth.token}"
                    else
                        res.send 400, "Redirect not allowed: #{req.body.redirectUri}"
                else
                    return res.send 400, "Invalid type #{req.body.type}"

oauthController.postAccessToken = (req, res) ->
    # TODO: Check parameters

    # Get and verify the client is who he says he is
    Client.findOne _id: req.body.client_id, (err, client) ->
        if err and err.name is 'CastError' then return res.send(404, 'Cannot find client')
        if err then return res.send(500, err.toString())
        if not client then return res.send(404, 'Cannot find client')

        # Valid requests must include the client secret
        if client.secret isnt req.body.client_secret
            return res.send(401, 'Invalid client secret')

        # Make sure the grant exists and is valid
        Grant.findOne code: req.body.code, (err, grant) ->
            if err then return res.send(500, err.toString())
            if not grant then return res.send(404, 'Cannot find grant')

            if not grant.clientId.equals(client.id)
                return res.send(401, 'Grant does not match client ID')

            authFromGrant grant, (err, auth) ->
                if err then return res.send 500, err.toString()

                res.json
                    access_token: auth.token
                    token_type: 'bearer'
