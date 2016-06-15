var express = require('express');
var controller = require('./alumno-controller.js');

var router = express.Router();


//home page
router.get('/', function(req, res) {
    res.send('It is the student\'s home page!');  
});

//recibir preguntar de otros alumnos
router.post(controller.question.create.path, controller.question.create.handler);

//recibir contestaciones de los profesores
router.post(controller.answer.create.path, controller.answer.create.handler);


module.exports = router;