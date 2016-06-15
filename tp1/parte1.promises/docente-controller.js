var teacher = require("./docente-domain-teacher.js");

var controller = {
    
    inbox: {
        question: {
            path: '/inbox/question',
            handler: function(req, res){
                console.info('+registerQuestion | ' + JSON.stringify(req.body));
                global.teacher.registerQuestion(
                    req.body.id,
                    req.body.topic,
                    req.body.content,
                    req.body.date,
                    function(data){
                        console.info('-registerQuestion | ' + JSON.stringify(data));
                        res.end();
                    },
                    function(){
                        console.error('-registerQuestion | internal error');
                        res.statusCode = 505;
                        res.end('Question was not registered because an error ocurred.');
                    }
                );
            }
        },
        
        answer: {
            path: '/inbox/answer',
            handler: function(req, res){
                console.log("inbox answer: " + req.body.id);
                res.end();
            }
        }
    }
}


module.exports = controller;