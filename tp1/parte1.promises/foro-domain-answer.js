var Sequence = require('./other-sequence.js');

var sqAnswer = new Sequence(100);

var Answer = function(question, author, content, date){
    this.author = author;
    this.content = content;
    this.question = question; 
    this.id = sqAnswer.next();
    this.date = date || Date.now();
}



module.exports = Answer;