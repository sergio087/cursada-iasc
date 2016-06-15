var express = require('express');
var controller = require('./alumno-controller.js');

var router = express.Router();


//home page
router.get('/', function(req, res) {
    res.send('is is alumno the home page!');  
});

//recibir preguntar de otros alumnos
router.post(controller.inbox.question.path, controller.inbox.question.handler);

//recibir contestaciones de los profesores
router.post(controller.inbox.answer.path, controller.inbox.answer.handler);


module.exports = router;