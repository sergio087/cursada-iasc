var Question = require('./docente-domain-question.js');
var Promise = require('bluebird');

var Teacher = function(name, host){
    this.name = name;
    this.id = null;
    this.host = host;
    this.questions = [];
    this.promiseByQuestion = [];
    
    this.signInForum();
}

Teacher.prototype.resolveQuestion = function(questionId, questionTopic, questionContent, questionDate, next, error){
    var self = this;
    
    self.registerQuestion(
        questionId, 
        questionTopic, 
        questionContent, 
        questionDate 
    ).catch(function(message){
        error(message);
    }).then(function(question){
        next(question);
        return self.thinkAnswer(question);
    }).then(function(question){
        return self.notifyIntendedToAnswer(question);
    }).then(function(question){
        return self.writeAnswer(question);
    }).then(function(question){
        return self.sendAnswer(question);
    }).catch(function(error){
       //no tengo q seguir contestando, alguien fue mas rapido
        console.error('Warning! resolveQuestion - (by reject)' + error);
    }).finally(function(){
        if(self.getPromiseByQuestion(questionId).isCancelled())
            console.error('Warning! resolveQuestion - (by cancel) no tengo q seguir contestando, alguien fue mas rapido');
    });
}

Teacher.prototype.registerQuestion = function(questionId, questionTopic, questionContent, questionDate){
    var self = this;
    
    return new Promise(function(resolve,reject){
        //TODO manejar duplicados con reject
        var question = new Question(questionId, questionTopic, questionContent, questionDate);
        self.questions.push(question);
        resolve(question);
    });
}

Teacher.prototype.thinkAnswer = function(question){
    
    var promise = new Promise.delay(Math.round(Math.random() * 10000)).return(question);
    
    /*
    var promise = new Promise(function(resolve,reject){
        setTimeout(function(){ resolve(question)}, Math.round(Math.random() * 10000));
    });
    */
    
    this.addPromiseByQuestion(question.id, promise);
    
    return promise;
}

Teacher.prototype.notifyIntendedToAnswer = function(question){
    var self = this;
    
    return new Promise(function(resolve, reject){
        //registro fecha de creacion respuesta
        question.answerCreationDate = Date.now();
        
        //envio intencion de respuesta
        var post_data = JSON.stringify({answerAuthorId: self.id, answerCreationDate: question.answerCreationDate});
        var post_options = {
            host: global.forum_host.host,
            port: global.forum_host.port,
            path: '/question/' + question.id + '/answer',
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Content-Length': Buffer.byteLength(post_data)
            }
        }
        var http = require('http');
        var req = http.request(
            post_options,
            function(res){

                var res_body = new String();

                res.on('data',function(chunk){
                    res_body += chunk;
                });
                res.on('end', function (chunk){
                    res_body = JSON.parse(res_body);

                    if (res_body.hasOwnProperty('error')){
                        //la pregunta ya fue respondida por otro
                        console.error('notifyIntendedToAnswer | ' + res_body.message);
                        reject(res_body.message);
                    } else {
                        //mi respuesta fue la primera en registrarse, fue aceptada.
                        question.answerId = res_body.id;
                        console.info('notifyIntendedToAnswer | answer id ' + question.answerId + ' was assigned.');
                        resolve(question);
                    }
                });
            }
        );
        
        req.on('error', function(e) {
            console.error('notifyIntendedToAnswer | problem with request: ' + e.message);
        });

        req.write(post_data);
        req.end();
    })
}

Teacher.prototype.writeAnswer = function(question){
    var self = this;
    
    return new Promise(function(resolve, response){
        question.answerFulfillmentDate = Date.now();
        question.answerContent = 'rta ' + self.name;
        
        resolve(question);
    });
}

Teacher.prototype.sendAnswer = function(question){
    var self = this;
    
    return new Promise(function(resolve, reject){
        
        var http = require('http');
    
        var req_data = 
            JSON.stringify({
                answerAuthorId: self.id,
                answerContent: question.answerContent,
                answerFulfillmentDate: question.answerFulfillmentDate
            });
        
        var req_options = {
            host: global.forum_host.host,
            port: global.forum_host.port,
            path: '/question/' + question.id + '/answer',
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Content-Length': Buffer.byteLength(req_data)
            }
        }
        
        var req = http.request(
            req_options,
            function(res){

                var res_body = new String();

                res.on('data',function(chunk){
                    res_body += chunk;
                });
                res.on('end', function (chunk) {
                    res_body = JSON.parse(res_body);

                    if (res_body.hasOwnProperty('error')){
                        console.error('sendAnswer | ' + res_body.message);
                        reject(res_body.message);
                    } else {
                        question.answerId = res_body.id;
                        console.info('sendAnswer | ' + JSON.stringify(question));
                        resolve(res_body);
                    }
                });
            }
        );

        req.on('error', function(e) {
          console.error('sendAnswer | problem with request: ' + e.message);
        });

        req.write(req_data);
        req.end();
    })
}


Teacher.prototype.signInForum = function(){
    var self = this;
    
    var http = require('http');
    
    var post_data = JSON.stringify(self);
    
    var post_options = {
        host: global.forum_host.host,
        port: global.forum_host.port,
        path: '/teacher',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(post_data)
        }
    }
    
    var req = http.request(
        post_options,
        function(res){
            var res_body = new String();
            
            res.on('data',function(chunk){
                res_body += chunk;
            });
            
            res.on('end', function(){
                res_body = JSON.parse(res_body);
                
                if (res_body.hasOwnProperty('error')){
                    console.error('signInForum | ' + res_body.message);
                } else {
                    self.id = res_body.id;
                    console.info('signInForum | teacher id ' + self.id + ' was assigned.');
                }
            });
        }
    );
    
    req.on('error', function(e) {
      console.error('signInForum | problem with request: ' + e.message);
    });

    req.write(post_data);
    req.end();
}


Teacher.prototype.discardQuestion = function(questionId, next, error){
    var question = this.questions.filter(function(q){return q.id == questionId})[0];
    if(question){
        this.getPromiseByQuestion(questionId)._cancel();
        next(question);
    }else
        error("question not found");
}

Teacher.prototype.addPromiseByQuestion = function(questionId, promise){
    this.promiseByQuestion.push({key: questionId, value: promise});
    return promise;
}

Teacher.prototype.getPromiseByQuestion = function(questionId){
    var results = 
        this.promiseByQuestion.filter(
            function(association){
                return association.key == questionId;
            }
        );
    return results[0].value;
}

Teacher.prototype.removePromiseByQuestion = function(questionId){
    var removed = this.promiseByQuestion.filter(function(association){return association.key == questionId})[0];
    var index = this.promiseByQuestion.indexOf(removed,0);
    this.promiseByQuestion.splice(index,1);
    
    return removed.value;
}

Teacher.prototype.hasPromiseByQuestion = function(questionId){
    var results = 
        this.promiseByQuestion.filter(
            function(association){
                return association.key == questionId;
            }
        );
    
    return results > 0;
}


module.exports = Teacher;




