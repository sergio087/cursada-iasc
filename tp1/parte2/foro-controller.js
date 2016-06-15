var controller = {
    
    question: {
        
        create: {
            path: '/question',
            handler: function(req, res){
                console.info('+registerQuestion | ' + JSON.stringify(req.body));
                
                if(req.body.hasOwnProperty('studentId') && req.body.hasOwnProperty('questionContent') && req.body.hasOwnProperty('questionTopic'))
                    global.forum.registerQuestion(
                        req.body.studentId, 
                        req.body.questionTopic,
                        req.body.questionContent, 
                        function(data){
                            console.info('-registerQuestion | ' + JSON.stringify(data) + '\n');
                            res.set('Content-Type', 'application/json');
                            res.end(JSON.stringify({id:data.id}));
                        },
                        function(message){
                            console.error('-registerQuestion | ' + message + '\n');
                            res.statusCode = 505;
                            res.set('Content-Type', 'application/json');
                            res.end(JSON.stringify( {error: 'validation', message: message}));
                        }
                    );
                else {
                    console.error('-registerQuestion | parameter error\n');
                    res.statusCode = 404;
                    res.set('Content-Type', 'application/json');
                    res.end(JSON.stringify( {error: 'format', message: 'Bad question format.'}));
                }
            }
        },
        
        read: {
            path:'/question/:id',
            handler: function(req, res){
                //TODO pasar a domain
                var id = req.params.id;
                var question = global.forum.questions.filter(function(q){return q.id == id}).pop();
                res.set('Content-Type', 'application/json');
                res.end(JSON.stringify(question));
            }
        }
    },
    
    answer: {
        
        create: {
            path: '/question/:id/answer',
            handler: function(req, res){
                console.info('+registerAnswer | ' + JSON.stringify(req.body));
                
                if(req.body.hasOwnProperty('answerAuthorId')  && req.body.hasOwnProperty('answerCreationDate'))
                    global.forum.registerAnswer(
                        req.params.id,
                        req.body.answerAuthorId,
                        req.body.answerDate,
                        function(answer){
                            console.info('-registerAnswer | new answer id ' + answer.id + '\n');
                            res.set('Content-Type', 'application/json');
                            res.end(JSON.stringify({id: answer.id}));
                        },
                        function(message){
                            console.error('-registerAnswer | ' + message + '\n');
                            res.statusCode = 505;
                            res.set('Content-Type', 'application/json');
                            res.end(JSON.stringify( {error: 'validation', message: message}));
                        }
                    );
                else {
                    console.error('-registerAnswer | parameter error\n');
                    res.statusCode = 404;
                    res.set('Content-Type', 'application/json');
                    res.end(JSON.stringify( {error: 'format', message: 'Bad question format.'}));
                }
            }
        },
        
        update: {
            path: '/question/:id/answer',
            handler: function(req, res){
                console.info('+fulfillAnswer | ' + JSON.stringify(req.body));
              
                if(req.body.hasOwnProperty('answerAuthorId') && req.body.hasOwnProperty('answerFulfillmentDate') && req.body.hasOwnProperty('answerContent')){
                    global.forum.fulfillAnswer(
                        req.params.id,
                        req.body.answerAuthorId,
                        req.body.answerContent,
                        req.body.answerFulfillmentDate,
                        function(answer){ // comple la repsuesta ok
                            console.info('-fulfillAnswer | answer id ' + answer.id);
                            res.set('Content-Type', 'application/json');
                            res.end(JSON.stringify({id: answer.id}));
                        },
                        function(error){ // error al completar la repsuesta
                            console.error('-fulfillAnswer | ' + error);
                            res.statusCode = 505;
                            res.end(error);
                        }
                    );
                } else{
                    console.error('-fulfillAnswer | parameter error\n');
                    res.statusCode = 404;
                    res.set('Content-Type', 'application/json');
                    res.end(JSON.stringify( {error: 'format', message: 'Bad question format.'}));    
                }
                
            }
        },
        
        read: {
            path: '/question/:id/answer',
            handler: function(req, res){
                var questionId = Number(req.params.id);
                var filteredQuestions = global.forum.questions.filter(function(q){return q.id == questionId});
                if( filteredQuestions.length > 0){
                    var answer = filteredQuestions[0].answer();
                    res.set('Content-Type', 'application/json');
                    res.end(JSON.stringify({id: answer.id, author: answer.author, content: answer.content, creationDate: answer.creationDate, fulfillmentDate: answer.fulfillmentDate, questionId: answer.question.id}));
                }else{
                    res.statusCode = 404;
                    res.end('Not Found');
                }
            }
        }
    },
    
    student: {
        
        create: {
            path: '/student',
            handler: function(req, res){
                console.info('+registerStudent | ' + JSON.stringify(req.body));
                
                global.forum.registerStudent(
                    req.body.name, 
                    req.body.host, 
                    function(student){
                        console.info('-registerStudent | ' + JSON.stringify(student) + '\n');
                        res.set('Content-Type', 'application/json');
                        res.write(JSON.stringify(student));
                        res.end();
                    },
                    function(message){
                        var error = {error: 'validation', message: message};
                        console.error('-registerStudent | ' + message + '\n');
                        res.statusCode = 404;
                        res.end(JSON.stringify(error));
                    }
                );
            } 
        },
                
        read: {
            path: '/student/:name',
            handler: function(req, res){
                console.info('+findStudent | ' + req.params.name);
                global.forum.findStudent(
                    req.params.name, 
                    'name',
                    function(student){  //found
                        console.info('-findStudent | ' + JSON.stringify(student) + '\n');
                        res.set('Content-Type', 'application/json');
                        res.end(JSON.stringify(student));
                    }, function(message){  //not found
                        console.error('-findStudent | ' + message + '\n');
                        res.statusCode = 404;
                        res.set('Content-Type', 'application/json');
                        res.end(JSON.stringify( {error: 'validation', message: message}));
                    }
                );
            }
        },
        
        readAll: {
            path: '/student',
            handler: function(req, res){
                res.end(JSON.stringify(global.forum.students));
            }
        
        },
        
        update: {
            path: '/student/:name',
            handler: function(req, resp){
                
            }
        },
        
        delete: {
            path: '/student/:name',
            handler: function(req, resp){
                
            }
        }
    },
    
    teacher: {
        
        create: {
            path: '/teacher',
            handler: function(req, res){
                console.info('+registerTeacher | ' + JSON.stringify(req.body));

                global.forum.registerTeacher(
                    req.body.name, 
                    req.body.host, 
                    function(teacher){
                        console.info('-registerTeacher | ' + JSON.stringify(teacher) + '\n');
                        res.set('Content-Type', 'application/json');
                        res.write(JSON.stringify({id:teacher.id}));
                        res.end();
                    },
                    function(message){
                        var error = {error: 'validation', message: message};
                        console.error('-registerTeacher | ' + message + '\n');
                        res.statusCode = 505;
                        res.end(JSON.stringify(error));
                    }
                );
            } 
        },
        
        read: {
            path: '/teacher/:name',
            handler: function(req, res){
                console.info('+findTeacher | ' + req.params.name);
                global.forum.findTeacher(
                    req.params.name,
                    'name',
                    function(teacher){  //found
                        console.info('-findTeacher | ' + JSON.stringify(teacher) + '\n');
                        res.end(JSON.stringify(teacher));
                    }, 
                    function(message){  //not found
                        console.info('-findTeacher | ' + message + '\n');
                        res.statusCode = 404;
                        res.set('Content-Type', 'application/json');
                        res.end(JSON.stringify( {error: 'validation', message: message}));
                    }
                )
            }
        },
        
        update: {
            path: '/teacher/:name',
            handler: function(req, resp){
                
            }
        },
        
        delete: {
            path: '/teacher/:name',
            handler: function(req, resp){
                
            }
        }
    }
}

module.exports = controller;