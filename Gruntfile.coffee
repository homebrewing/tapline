module.exports = (grunt) ->
    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'
        external_daemon:
            mongodb:
                options:
                    startCheck: (stdout, stderr) ->
                        /waiting for connections/i.test stdout
                cmd: 'mongod'
                args: ['--dbpath', 'db']
            beanstalkd:
                cmd: 'beanstalkd'
        shell:
            'dbdir':
                command: 'mkdir -p db'
            'drop-test-db':
                command: 'mongo tapline_test --exec "db.dropDatabase()"'
        coffeelint:
            options:
                indentation:
                    value: 4
                max_line_length:
                    value: 120
                    level: 'warn'
            tapline:
                expand: true
                src: ['src/**/*.coffee', 'test/**/*.coffee']
        coffee:
            tapline:
                expand: true
                cwd: 'src'
                src: ['**/*.coffee']
                dest: 'lib'
                ext: '.js'
            tests:
                expand: true
                cwd: 'test'
                src: ['**/*.coffee']
                dest: 'test-js'
                ext: '.js'
        watch:
            tapline:
                files: ['src/**.coffee']
                tasks: ['compile', 'server', 'worker']
                options:
                    nospawn: true
        mochacov:
            test:
                options:
                    reporter: 'spec'
                    grep: grunt.option('grep')
                src: 'test-js/**/*.js'
            html:
                options:
                    reporter: 'html-cov'
                    output: 'coverage.html'
                src: 'test-js/**/*.js'
            reportcoverage:
                options:
                    coveralls:
                        serviceName: 'travis-ci'
                src: 'test-js/**/*.js'

    grunt.loadNpmTasks 'grunt-external-daemon'
    grunt.loadNpmTasks 'grunt-shell'
    grunt.loadNpmTasks 'grunt-coffeelint'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-mocha-cov'

    # The following is to run services during development and restart
    # them as needed. Normally you could use grunt-develop, but it is
    # limited to a single process and I need at least two: the API server
    # and a job queue worker.
    processes = {}
    rundev = (name, command) ->
        return ->
            # Kill the process if it is currently running
            if processes[name]
                processes[name].kill()
                delete processes[name]

            # Spawn the new process
            processes[name] = grunt.util.spawn cmd: process.argv[0], args: [command], -> false

            # Print info when exiting or writing output to stdout
            processes[name].on 'exit', (code, signal) ->
                grunt.log.warn "#{name} exiting"

            processes[name].stdout.on 'data', (buffer) ->
                grunt.log.write "[#{name}] > ".cyan + String(buffer)

            grunt.log.write '>> '.green + "Started #{name}"

    # Cleanup any spawned processes on Ctrl-C
    process.on 'exit', ->
        for name, child of processes
            child.kill()

    grunt.registerTask 'worker', 'Start a job queue worker', rundev('worker', 'bin/tapline-worker.js')
    grunt.registerTask 'server', 'Start a server', rundev('tapline', 'bin/tapline.js')

    grunt.registerTask 'compile', ['coffeelint', 'coffee']
    grunt.registerTask 'db', ['shell:dbdir', 'external_daemon:mongodb']
    grunt.registerTask 'queue', ['external_daemon:beanstalkd']
    grunt.registerTask 'test', ['db', 'shell:drop-test-db', 'compile', 'mochacov:test']
    grunt.registerTask 'coverage', ['db', 'shell:drop-test-db', 'compile', 'mochacov:html']
    grunt.registerTask 'coveralls', ['db', 'shell:drop-test-db', 'compile', 'mochacov:reportcoverage']
    grunt.registerTask 'default', ['db', 'queue', 'compile', 'server', 'worker', 'watch']
