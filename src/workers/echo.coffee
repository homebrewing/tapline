class EchoWorker
    type: 'echo'

    work: (payload, done) ->
        console.log payload
        done 'success'

module.exports = ->
    new EchoWorker()
