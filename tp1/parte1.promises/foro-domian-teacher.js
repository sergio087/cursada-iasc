var Sequence = require('./other-sequence.js');

var sqTeacher = new Sequence();

var Teacher = function(name, endpoint){
    
    this.name = name;
    this.endpoint = endpoint;
    this.id = sqTeacher.next();
}

module.exports = Teacher;