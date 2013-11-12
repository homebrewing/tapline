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
            tapline_worker:
                cmd: './bin/tapline-worker.js'
                options:
                    verbose: true
            tapline:
                cmd: './bin/tapline.js'
                options:
                    verbose: true
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
                tasks: ['server']
            worker:
                files: ['src/worker/**.coffee']
                tasks: ['worker']
        mochacov:
            test:
                options:
                    reporter: 'spec'
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
    grunt.loadNpmTasks 'grunt-coffeelint'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-mocha-cov'

    grunt.registerTask 'compile', ['coffeelint', 'coffee']
    grunt.registerTask 'db', ['external_daemon:mongodb']
    grunt.registerTask 'queue', ['external_daemon:beanstalkd']
    grunt.registerTask 'worker', ['external_daemon:tapline_worker']
    grunt.registerTask 'server', ['external_daemon:tapline']
    grunt.registerTask 'test', ['compile', 'mochacov:test']
    grunt.registerTask 'default', ['db', 'queue', 'compile', 'server', 'worker', 'watch']
