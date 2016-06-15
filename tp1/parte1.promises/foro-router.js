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


// recibir una pregunta
router.post(controller.forum.ask.path, controller.forum.ask.handler);

// recibir una respuesta
router.post(controller.forum.answer.path, controller.forum.answer.handler);


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