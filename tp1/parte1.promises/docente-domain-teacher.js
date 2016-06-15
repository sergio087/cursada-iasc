var Question = require('./docente-domain-question.js');

var Teacher = function(name, host){
    this.name = name;
    this.id = null;
    this.host = host;
    this.questions = [];
    
    this.signInForum();
}

Teacher.prototype.registerQuestion = function(questionId, questionTopic, questionContent, questionDate, next){
    var question = new Question(questionId, questionTopic, questionContent, questionDate);
    this.questions.push(question);
    setTimeout(function(){this.processQuestion(question)}, Math.round(Math.random() * 1000));
    next(question);
}

Teacher.prototype.processQuestion = function(question){
    console.info('+processQuestion | ' + question.id);
    
    //escribo respuesta
    question.answerDate = Date.now();
    question.answerContent = 'rta ' + this.name;
    
    //envio la respuesta al foro
    var self = this;
    
    var http = require('http');
    
    var post_data = 
        JSON.stringify({
            questionId: question.id, 
            answerAuthorId: self.id,
            answerContent: question.answerContent,
            answerDate: question.answerDate
        });
    
    var post_options = {
        host: global.forum_host.host,
        port: global.forum_host.port,
        path: '/answer',
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
            res.on('end', function (chunk) {
                res_body = JSON.parse(res_body);
                
                if (res_body.hasOwnProperty('error')){
                    console.error('-processQuestion | ' + res_body.message);
                } else {
                    question.answerId = res_body.id;
                    console.info('-processQuestion | answer id ' + question.id + ' was assigned.');
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


module.exports = Teacher;




