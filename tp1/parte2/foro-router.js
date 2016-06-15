var express = require('express');
var controller = require('./foro-controller.js');

var router = express.Router();

/*
router.param('forum', function(req,res, next, forum){
    
})
*/

//home page
router.get('/', function(req, res) {
    res.send('it is a forum server!');  
});


// CR pregunta
router.post(controller.question.create.path, controller.question.create.handler);
router.get(controller.question.read.path, controller.question.read.handler);

// CU respuesta
router.post(controller.answer.create.path, controller.answer.create.handler);
router.put(controller.answer.update.path, controller.answer.update.handler);
router.get(controller.answer.read.path, controller.answer.read.handler);

//CRUD alumno
router.post(controller.student.create.path, controller.student.create.handler);
router.get(controller.student.read.path, controller.student.read.handler);
router.put(controller.student.update.path, controller.student.update.handler);
router.delete(controller.student.delete, controller.student.delete.handler);

//CRUD docente
router.post(controller.teacher.create.path, controller.teacher.create.handler);
router.get(controller.teacher.read.path, controller.teacher.read.handler);
router.put(controller.teacher.update.path, controller.teacher.update.handler);
router.delete(controller.teacher.delete, controller.teacher.delete.handler);


module.exports = router;