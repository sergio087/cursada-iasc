var teacher = require("./docente-domain-teacher.js");

var controller = {
    
    question: {
        create: {
            path: '/inbox/question',
            handler: function(req, res){
                console.info('+resolveQuestion | ' + JSON.stringify(req.body));
                global.teacher.resolveQuestion(
                    req.body.id,
                    req.body.topic,
                    req.body.content,
                    req.body.date,
                    function(data){ // question can be resolved
                        console.info('-resolveQuestion | ' + JSON.stringify(data)+ '\n');
                        res.end();
                    },
                    function(error){ // question cannot be resolverd
                        console.error('-resolveQuestion | internal error\n');
                        res.statusCode = 505;
                        res.end();
                    }
                );
            }
        },
        
        delete: {
            path: '/inbox/question/:id',
            handler: function(req,res){
                console.info('+discardQuestion | questionId ' + req.params.id);
                global.teacher.discardQuestion(
                    Number(req.params.id),
                    function(question){ //fue descartada
                        console.info('-discardQuestion | questionId ' + question.id);
                        res.set('Content-Type', 'application/json');
                        res.end(JSON.stringify({teacherId: global.teacher.id}));
                    },
                    function(message){ //no pudo se descartada
                        console.error('-discardQuestion | ' + message),
                        res.statusCode = 505;
                        res.set('Content-Type', 'application/json');
                        res.end(JSON.stringify({error: message}));
                    }
                )
            }
        }
    },
    
    answer: {
        create: {
            path: '/inbox/question/:id/answer',
            handler: function(req, res){
                console.log("inbox answer: " + req.body.id + " from question " + req.params.id);
                res.end();
            }
        }
    }
}


module.exports = controller;