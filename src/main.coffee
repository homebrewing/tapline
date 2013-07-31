#!/usr/bin/env node

config = require './config'

optimist = require('optimist')
    .usage("Usage: $0 [options] [--config /my/config.json] [--listen #{config.listen}]")
    .options 'c',
        alias: 'config'
        describe: 'Path to configuration file'
    .options 'l',
        alias: 'listen'
        describe: 'Listen on host:port'
    .options 's',
        alias: 'dbUrl'
        describe: 'MongoDB connection URL'
    .options 'h',
        alias: 'help'
        describe: 'Show help and exit'
        boolean: true
    .options 'v',
        alias: 'version'
        describe: "Show Tapline version and exit"
        boolean: true

argv = optimist.argv

if argv.h
    return optimist.showHelp()

if argv.v
    pkgInfo = require '../package'
    return console.log "Tapline #{pkgInfo.version}"

db = require './db'
log = require './log'
path = require 'path'
server = require './server'

# Setup logs to actually go somewhere, since by default
# they go nowhere
log.setup()

if argv.config
    log.info "Loading #{argv.config}..."
    config.load require(path.resolve(argv.config))

if argv.listen
    config.listen = argv.listen

if argv.dbUrl
    config.dbUrl = argv.dbUrl

# Connect to the database and start the HTTP server
db.connect config.dbUrl, (err) -> server.start config.listen
