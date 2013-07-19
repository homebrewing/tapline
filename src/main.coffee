#!/usr/bin/env node

optimist = require('optimist')
    .usage('Usage: $0 [options] [--listen localhost:8080]')
    .options 'l',
        alias: 'listen'
        describe: 'Listen on host:port'
        default: 'localhost:2337'
    .options 's',
        alias: 'dbUrl'
        describe: 'MongoDB connection URL'
        default: 'mongodb://localhost/tapline'
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
server = require './server'

# Setup logs to actually go somewhere, since by default
# they go nowhere
log.setup()

# Connect to the database and start the HTTP server
db.connect argv.dbUrl, (err) -> server.start argv.listen
