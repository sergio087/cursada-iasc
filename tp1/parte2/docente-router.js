var express = require('express');
var controller = require('./docente-controller.js');

var router = express.Router();


//home page
router.get('/', function(req, res) {
    res.send('It is the teacher\'s home page!');  
});

//question
router.post(controller.question.create.path, controller.question.create.handler);
router.delete(controller.question.delete.path, controller.question.delete.handler);

//answer
router.post(controller.answer.create.path, controller.answer.create.handler);


module.exports = router;