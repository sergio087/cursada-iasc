var express = require('express');
var controller = require('./docente-controller.js');

var router = express.Router();


//home page
router.get('/', function(req, res) {
    res.send('is is docente the home page!');  
});


router.post(controller.question.create.path, controller.question.create.handler);
router.delete(controller.question.delete.path, controller.question.delete.handler);
router.post(controller.answer.create.path, controller.answer.create.handler);


module.exports = router;