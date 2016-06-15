var express = require('express');
var bodyParser = require('body-parser');
var router = require('./foro-router.js');
var Forum = require('./foro-domain-forum.js');

if (process.argv.length == 4){
    
    var param_host = process.argv[3].split(':');
    var port = param_host[1];
    
    var param_name = process.argv[2];
    
    var app = express();

    app.use(bodyParser.json());
    app.use('/', router);

    global.forum = new Forum(param_name);

    app.listen(port);

    console.log('Magic happens on port ' + port);
    
} else {
    console.error('\nError! Bad parameters.\nUse: forum_name forum_host:forum_port\n');
}