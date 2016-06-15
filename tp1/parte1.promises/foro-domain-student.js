var Sequence = require('./other-sequence.js');

var sqStudent = new Sequence();

var Student = function(name, endpoint){
    
    this.name = name;
    this.endpoint = endpoint;
    this.id = sqStudent.next();
}

module.exports = Student;