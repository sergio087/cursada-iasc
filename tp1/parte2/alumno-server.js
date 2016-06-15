var express = require('express');
var bodyParser = require('body-parser');
var router = require('./alumno-router.js');
var Student = require("./alumno-domain-student.js");

var app = express();

app.use(bodyParser.json());
app.use('/', router);

if (process.argv.length == 5){
    //set student_name
    var student_name = process.argv[2];

    //set student_host
    var param_student = (process.argv[3]).toString().split(':'); 
    var student_host = {host: param_student[0], port:param_student[1]};

    //set forum_host
    var param_forum = (process.argv[4]).toString().split(':');
    global.forum_host = {host: param_forum[0], port:param_forum[1]};

    app.listen(student_host.port);

    console.log('Magic happens on port ' + student_host.port);
    global.student = new Student(student_name, student_host);    
    
} else {
    console.error('\nError! Bad parameters.\nUse: student_name student_host:student_port forum_host:forum_port\n');
}
