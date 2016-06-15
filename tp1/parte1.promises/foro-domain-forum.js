var Student = require('./foro-domain-student.js');
var Teacher = require('./foro-domian-teacher.js');
var Question = require('./foro-domain-question.js');
var Answer = require('./foro-domain-answer.js')
var Promise = require('bluebird');

var Forum = function(name){
    
    this.name = name;
    this.students = [];
    this.teachers = [];
    this.questions = [];
}

Forum.prototype.registerStudent = function(name, endpoint){
    var self = this;
    
    return new Promise(function(resolve, reject){
        self.findStudent(
            name,
            'name'
        )
        .then(function(stundent){
            reject({ error: 'validation', message: 'Endpoint ' + endpoint.host +':'+ endpoint.port + ' already exists.'});
        })
            .catch(function(error){
                return self.createStudent(name, endpoint);   
            })
                .then(function(student){
                    resolve(student);
                })
    });
}

Forum.prototype.createStudent = function(name, endpoint){
    var student = new Student(name, endpoint);
    this.students.push(student);
    return student;    
}

Forum.prototype.findStudent = function(pattern, property){
    var self = this;
    
    return new Promise(function(resolve, reject){
        self.finder(
            self.students, 
            0, 
            pattern, 
            property,
            function(student){
                resolve(student);
            },
            function(error){
                reject(new Error('Not found'));
           }
        );
    });
}

Forum.prototype.registerTeacher = function(name, endpoint){
    var self = this;
    
    return new Promise(function(resolve, reject){
        self.findTeacher(
            name,
            'name',
            function(teacher){
                reject({error: 'Error', message: 'Endpoint ' + endpoint.host +':'+ endpoint.port + ' already exists.'});
            },
            function(message){
                var teacher = self.createTeacher(name, endpoint);
                resolve(teacher);
            }
        );
    });
}

Forum.prototype.createTeacher = function(name, endpoint){
    var teacher = new Teacher(name, endpoint);
    this.teachers.push(teacher);
    return teacher;
}

Forum.prototype.findTeacher = function(pattern, property){
    var self = this;
    
    return new Promise(function(resolve, reject){
        self.finder(
            self.teachers, 
            0, 
            pattern, 
            property,
            function(teacher){
                resolve(teacher);
            },
            function(error){
                reject(new Error('Not found'));
           }
        );
    });
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

Forum.prototype.registerQuestion = function(studentId, questionTopic, questionContent){
    var self = this;
    
    return new Promise(function(resolve, reject ){
        self.findStudent(
            studentId,
            'id')
        .then(function(student){
            var question = new Question(student, questionTopic, questionContent, Date.now());
            self.questions.push(question);
            self.processQuestion(question);
            resolve(question);
        })
        .catch(function(error){
            reject(error);
        });
    });
}

Forum.prototype.processQuestion = function(question){
    var self = this;
    
    self.teachers.forEach(function(teacher){
        self.broadcastQuestion(teacher, question);
    });
    
    self.students.forEach(function(student){
        if (student.id != question.author.id)
            self.broadcastQuestion(student, question);
    });
}

Forum.prototype.broadcastQuestion = function(receiber, question){
    
    var http = require('http');
    
    console.info('broadcastQuestion | ' + question.id + ' to ' + receiber.endpoint.host + ':' + receiber.endpoint.port);
    
    var post_data = JSON.stringify(question);
    console.log('broadcastQuestion | ' + post_data);
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
                console.error('broadcastQuestion | error on ' + receiber.name );
        }
    );
    
    req.on('error', function(e) {
      console.error('broadcastQuestion | problem with request: ' + e.message);
    });

    // write data to request body
    req.write(post_data);
    req.end();
}

Forum.prototype.registerAnswer = function(questionId, answerAuthorId, answerContent, answerDate, next, error){
    var self = this;
    
    self.findQuestion(
        questionId,
        'id',
        function(question){
            if(question.hasAnswers())
                error('Question '+ questionId +' has been already answered.');
            else {
                self.findTeacher(
                    answerAuthorId,
                    'id',
                    function(teacher){
                        var answer = question.registerAnswer(teacher, answerContent, answerDate);
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


module.exports = Forum;