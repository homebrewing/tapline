log = require '../log'

Action = require '../models/action'

class RecipeUpdatedWorker
    type: 'recipe-updated'

    work: (payload, done) ->
        log.info "Processing updated recipe #{payload.id}"

        Action.find {targetId: payload.id}, (err, actions) ->
            for action in actions
                log.debug "Action #{action.id}"
                action.data = payload.info
                action.save (err) ->
                    if err then console.log(err)

        # Create user action
        action = new Action
            user: payload.user
            type: 'recipe-updated'
            targetId: payload.id
            private: payload.private
            data: payload.info

        action.save()

        done 'success'

module.exports = ->
    new RecipeUpdatedWorker()
