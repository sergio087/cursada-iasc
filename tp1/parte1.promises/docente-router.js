var express = require('express');
var controller = require('./docente-controller.js');

var router = express.Router();


//home page
router.get('/', function(req, res) {
    res.send('is is docente the home page!');  
});

//recibir preguntas de los alumnos
router.post(controller.inbox.question.path, controller.inbox.question.handler);

//recibir contestaciones de otros profesores
router.post(controller.inbox.answer.path, controller.inbox.answer.handler);


module.exports = router;