var express = require('express');
var bodyParser = require('body-parser');
var router = require('./docente-router.js');
var Teacher = require("./docente-domain-teacher.js");

var app = express();

app.use(bodyParser.json());
app.use('/', router);

if (process.argv.length == 5){
    //set teacher_name
    var teacher_name = process.argv[2];

    //set teacher_host
    var param_teacher = (process.argv[3]).toString().split(':'); 
    var teacher_host = {host: param_teacher[0], port:param_teacher[1]};

    //set forum_host
    var param_forum = (process.argv[4]).toString().split(':');
    global.forum_host = {host: param_forum[0], port:param_forum[1]};

    app.listen(teacher_host.port);

    console.log('Magic happens on port ' + teacher_host.port);
    global.teacher = new Teacher(teacher_name, teacher_host);    
    
} else {
    console.error('\nError! Bad parameters.\nUse: teacher_name teacher_host:teacher_port forum_host:forum_port\n');
}
