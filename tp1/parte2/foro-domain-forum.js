var Student = require('./foro-domain-student.js');
var Teacher = require('./foro-domian-teacher.js');
var Question = require('./foro-domain-question.js');
var Answer = require('./foro-domain-answer.js')


var Forum = function(name){
    
    this.name = name;
    this.students = [];
    this.teachers = [];
    this.questions = [];
}

Forum.prototype.registerStudent = function(name, endpoint, next, error){
    var self = this;
    
    this.findStudent(
        name,
        'name',
        function(student){
            error('Endpoint ' + endpoint.host +':'+ endpoint.port + ' already exists.');
        },
        function(message){
            var student = self.createStudent(name, endpoint);
            next(student);
        }
    );
}

Forum.prototype.createStudent = function(name, endpoint){
    var student = new Student(name, endpoint);
    this.students.push(student);
    return student;
}

Forum.prototype.findStudent = function(pattern, property, found, notFound){
    this.finder(
        this.students, 
        0, 
        pattern, 
        property,
        found, 
        function(message){
            notFound('Student ' + message);
        }
    );
}

Forum.prototype.registerTeacher = function(name, endpoint, next, error){
    var self = this;
    
    this.findTeacher(
        name,
        'name',
        function(teacher){
            error('Endpoint ' + endpoint.host +':'+ endpoint.port + ' already exists.');
        },
        function(message){
            var teacher = self.createTeacher(name, endpoint);
            next(teacher);
        }
    );
}

Forum.prototype.createTeacher = function(name, endpoint){
    var teacher = new Teacher(name, endpoint);
    this.teachers.push(teacher);
    return teacher;
}

Forum.prototype.findTeacher = function(pattern, property, found, notFound){
    this.finder(
        this.teachers, 
        0, 
        pattern, 
        property,
        found, 
        function(message){
            notFound('Teacher ' + message);
        }
    );
}

Forum.prototype.finder= function(array, index, pattern, property, found, notFound) {
    if (index >= array.length){
        notFound(pattern + ' not found');
    }else if (array[index][property] == pattern){
        found(array[index]);
    }else{
        this.finder(array, index + 1, pattern, property, found, notFound);
    }
}

Forum.prototype.registerQuestion = function(studentId, questionTopic, questionContent, next, error){
    var self = this;
    
    self.findStudent(
        studentId,
        'id',
        function(student){
            var question = new Question(student, questionTopic, questionContent, Date.now());
            self.questions.push(question);
            self.broadcastQuestion(question);
            next(question);
        },
        error
    );
}

Forum.prototype.broadcastQuestion = function(question){
    var self = this;
    
    self.availableTeachers().forEach(function(teacher){
        self.sendQuestion(teacher, question);
    });
    
    self.students.forEach(function(student){
        if (student.id != question.author.id)
            self.sendQuestion(student, question);
    });
}

Forum.prototype.availableTeachers = function(){
    var self = this;
    
    return this.teachers.filter(function(t){
        return !self.questions.some(function(q){
            return q.isAnswered() && q.answer().isWrittenByAuthor(t) && !q.answer().isFulfilled();
        })
    });
}

Forum.prototype.sendQuestion = function(receiber, question){
    
    var http = require('http');
    
    console.info('sendQuestion | ' + question.id + ' to ' + receiber.endpoint.host + ':' + receiber.endpoint.port);
    
    var post_data = JSON.stringify(question);
    var post_options = {
        host: receiber.endpoint.host,
        port: receiber.endpoint.port,
        path: '/inbox/question',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(post_data)
        }
    }
    
    var req = http.request(
        post_options,
        function(res){
            if (res.statusCode != 200)
                console.error('-sendQuestion | error on ' + receiber.name );
        }
    );
    
    req.on('error', function(e) {
      console.error('-sendQuestion | problem with request: ' + e.message);
    });

    // write data to request body
    req.write(post_data);
    req.end();
}

Forum.prototype.registerAnswer = function(questionId, answerAuthorId, answerDate, next, error){
    var self = this;
    
    self.findQuestion(
        questionId,
        'id',
        function(question){
            if(question.isAnswered())
                error('Question '+ questionId +' has been already answered.');
            else {
                self.findTeacher(
                    answerAuthorId,
                    'id',
                    function(teacher){
                        var answer = question.registerAnswer(teacher, answerDate);
                        self.notifyTeachersAboutAnswer(answer);
                        next(answer);
                    },
                    function(){
                        error('Author ' + answerAuthorId +' does not exist.');
                    }
                );
                
            }
        }, 
        function(message){
            error('Question ' + questionId + ' does not exits.');
        }
    );
    
}

Forum.prototype.notifyTeachersAboutAnswer = function(answer){
    var self = this;
    this.teachers.forEach(function(teacher){
        if(teacher.id != answer.author.id)
            self.notifyTeacherAboutAnswer(teacher, answer);
    });
}

Forum.prototype.notifyTeacherAboutAnswer = function(teacher, answer){
    var http = require('http');
    var req_data = JSON.stringify({questionId: answer.question.id});
    var req_options = {
            host: teacher.endpoint.host,
            port: teacher.endpoint.port,
            path: '/inbox/question/' + answer.question.id,
            method: 'DELETE',
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

                if (res_body.hasOwnProperty('error')){ //TODO coordinar msj
                    console.error('notifyTeacherAboutAnswer | teacherId: '+ teacher.id +', error: ' + res_body.error);
                   
                } else {
                    console.info('notifyTeacherAboutAnswer | teacherId ' + res_body.teacherId);
                    
                }
            });
        }
    );

    req.on('error', function(e) {
      console.error('notifyTeacherAboutAnswer | (teacherId '+ teacher.id +') problem with request: ' + e.message);
    });

    req.write(req_data);
    req.end();
}

Forum.prototype.findQuestion = function(pattern, property, found, notFound){
    this.finder(
        this.questions,
        0,
        pattern,
        property,
        found,
        notFound
    );
}


Forum.prototype.fulfillAnswer = function(questionId, answerAuthorId, answerContent, answerFulfillmentDate, next, error){
    var self = this;
    
    this.findQuestion(
        questionId,
        'id',
        function(question){
            if(question.isAnswered()){
                var answer = question.answer();
                if(answer.author.id == answerAuthorId){
                    answer.fulfill(answerContent, answerFulfillmentDate);
                    self.broadcastAnswer(answer);
                    next(answer);
                } else
                    error('author != creator');
            } else
                error('question was not answered');
        },
        function(message){
            error(message);
        }
    )
}

Forum.prototype.broadcastAnswer = function(answer){
    var self = this;
    
    this.teachers.forEach(function(t){
        if(t.id != answer.author.id)
            self.sendAnswer(t, answer);
    });
    
    this.students.forEach(function(s){
        self.sendAnswer(s, answer);
    });
}

Forum.prototype.sendAnswer = function(receiber, answer){
    var http = require('http');
    
    console.info('sendAnswer | ' + answer.id + ' to ' + receiber.endpoint.host + ':' + receiber.endpoint.port);
    
    var post_data = answer.toJSON();

    var post_options = {
        host: receiber.endpoint.host,
        port: receiber.endpoint.port,
        path: '/inbox/question/'+ answer.question.id +'/answer',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(post_data)
        }
    }
    
    var req = http.request(
        post_options,
        function(res){
            if (res.statusCode != 200)
                console.error('sendAnswer | error on ' + receiber.name );
        }
    );
    
    req.on('error', function(e) {
      console.error('sendAnswer | problem with request: ' + e.message);
    });

    // write data to request body
    req.write(post_data);
    req.end();
}


module.exports = Forum;