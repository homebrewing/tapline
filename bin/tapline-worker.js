#!/usr/bin/env node
config = require('../lib/config');
db = require('../lib/db');
log = require('../lib/log');

log.setup()

db.connect(config.dbUrl, function (err) {
    if (err) return console.log(err);

    var fivebeans = require('fivebeans');
    var runner = new fivebeans.runner('tapline-1', 'beanworker.yaml');
    runner.go();

    log.info('Tapline worker started')
});
