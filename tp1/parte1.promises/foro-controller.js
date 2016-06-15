var controller = {
    
    forum: {
        
        ask: {
            path: '/ask',
            handler: function(req, res){
                console.info('+registerQuestion | ' + JSON.stringify(req.body));
                
                if(req.body.hasOwnProperty('studentId') && req.body.hasOwnProperty('questionContent') && req.body.hasOwnProperty('questionTopic'))
                    global.forum.registerQuestion(
                        req.body.studentId, 
                        req.body.questionTopic,
                        req.body.questionContent)
                    .then(function(data){
                        console.info('-registerQuestion | ' + JSON.stringify(data));
                        res.set('Content-Type', 'application/json');
                        res.end(JSON.stringify({id:data.id}));
                        })
                    .catch(function(error){
                            console.error('-registerQuestion | ' + message);
                            res.statusCode = 505;
                            res.set('Content-Type', 'application/json');
                            res.end(JSON.stringify( {error: 'validation', message: message}));
                        });
                else {
                    console.error('-registerQuestion | parameter error ');
                    res.statusCode = 404;
                    res.set('Content-Type', 'application/json');
                    res.end(JSON.stringify( {error: 'format', message: 'Bad question format.'}));
                }
            }
        },
        
        answer: {
            path: '/answer',
            handler: function(req, res){
                console.info('+registerAnswer | ' + JSON.stringify(req.body));
                
                if(req.body.hasOwnProperty('questionId') && req.body.hasOwnProperty('answerAuthorId') && req.body.hasOwnProperty('answerContent') && req.body.hasOwnProperty('answerDate'))
                    global.forum.registerAnswer(
                        req.body.questionId,
                        req.body.answerAuthorId,
                        req.body.answerContent,
                        req.body.answerDate,
                        function(answer){
                            console.info('-registerAnswer | new answer id ' + answer.id);
                            res.set('Content-Type', 'application/json');
                            res.end(JSON.stringify({id: answer.id}));
                        },
                        function(message){
                            console.error('-registerQuestion | ' + message);
                            res.statusCode = 505;
                            res.end(JSON.stringify( {error: 'validation', message: message}));
                        }
                    );
                else {
                    console.error('-registerAnswer | parameter error ');
                    res.statusCode = 404;
                    res.end(JSON.stringify( {error: 'format', message: 'Bad question format.'}));
                }
            }
        }
    },
    
    student: {
        
        create: {
            path: '/student',
            handler: function(req, res){
                console.info('+registerStudent | ' + JSON.stringify(req.body));
                
                global.forum.registerStudent(req.body.name, req.body.host)
                    .then( function(student){
                            console.info('-registerStudent | ' + JSON.stringify(student));
                            res.set('Content-Type', 'application/json');
                            res.write(JSON.stringify(student));
                            res.end();
                        })
                    .catch(function(error){
                            console.error('-registerStudent | ' + JSON.stringify(error));
                            res.statusCode = 404;
                            res.end(JSON.stringify(error));
                        }
                    );
            } 
        },
                
        read: {
            path: '/student/:id',
            handler: function(req, res){
                
                global.forum.findStudent(
                    req.params.id, 
                    'id')
                .then(function(student){
                        console.info('findStudent | ' + JSON.stringify(student));
                        res.set('Content-Type', 'application/json');
                        res.end(JSON.stringify(student));
                    })
                .catch(function(error){
                    var myError = {error: 'validation', message: error.message};
                    console.info('findStudent | ' + JSON.stringify(myError));
                    res.statusCode = 404;
                    res.set('Content-Type', 'application/json');
                    res.end(JSON.stringify(myError));
                });
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

                global.forum.registerTeacher(req.body.name, req.body.host)
                    .then(function(teacher){
                            console.info('-registerTeacher | ' + JSON.stringify(teacher));
                            res.set('Content-Type', 'application/json');
                            res.write(JSON.stringify({id:teacher.id}));
                            res.end();
                        })
                    .catch(function(error){
                        console.error('-registerTeacher | ' + JSON.stringify(error));
                        res.statusCode = 404;
                        res.end(JSON.stringify(error));
                        });
            } 
        },
        
        read: {
            path: '/teacher/:id',
            handler: function(req, res){
                global.forum.findTeacher(
                    req.params.id,
                    'id')
                .then(function(teacher){
                    console.info('findTeacher | ' + JSON.stringify(teacher));
                    res.end(JSON.stringify(teacher));
                })
                .catch(function(error){
                    var my_error = {error: 'validation', message: error.message};
                    console.info('findTeacher | ' + JSON.stringify(my_error));
                    res.statusCode = 404;
                    res.set('Content-Type', 'application/json');
                    res.end(JSON.stringify(my_error));
                });
            }
        },
        
        update: {
            path: '/teacher/:id',
            handler: function(req, resp){
                
            }
        },
        
        delete: {
            path: '/teacher/:id',
            handler: function(req, resp){
                
            }
        }
    }
}

module.exports = controller;