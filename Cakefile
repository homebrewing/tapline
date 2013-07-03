{exec} = require 'child_process'

# Run a command, logging output and errors. Calls `callback` if given
# which should be a function taking no arguments. If an error is
# encountered, then the process is aborted with an error return
# code.
run = (cmd, callback) ->
    exec cmd, (err, stdout) ->
        if stdout then console.log stdout
        if err
            console.log err
            process.exit 1
        callback?(err)

task 'build', 'Build lib from src', ->
    console.log 'Checking code quality...'
    run './node_modules/coffeelint/bin/coffeelint -f test/lint.json -r src test', ->
        console.log 'Compiling src...'
        run './node_modules/coffee-script/bin/coffee -o lib --compile src'
        run './node_modules/coffee-script/bin/coffee --compile test'

task 'watch', 'Rebuild while watching for changes', ->
    run './node_modules/coffee-script/bin/coffee --watch -o lib --compile src'

task 'test', 'Run library tests', ->
    run './node_modules/mocha/bin/mocha -R spec --colors --recursive test'

task 'updateCoverage', 'Generate and push unit test code coverage info to coveralls.io', ->
    run './node_modules/istanbul/lib/cli.js cover -v ./node_modules/mocha/bin/_mocha -- --recursive test', ->
        run './node_modules/istanbul/lib/cli.js report lcovonly', ->
            console.log 'Trying to send coverage information to coveralls...'
            run './node_modules/coveralls/bin/coveralls.js <coverage/lcov.info'

task 'coverage', 'Determine unit test code coverage', ->
    run './node_modules/istanbul/lib/cli.js cover -v ./node_modules/mocha/bin/_mocha -- --recursive test', ->
        run './node_modules/istanbul/lib/cli.js report html'
