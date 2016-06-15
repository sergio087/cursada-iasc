var Sequence = require('./other-sequence.js');

var sqAnswer = new Sequence(100);

var Answer = function(question, author, date){
    this.author = author;
    this.content = '';
    this.question = question; 
    this.id = sqAnswer.next();
    this.creationDate = date || Date.now();
    this.fulfillmentDate = null;
}

Answer.prototype.isAnsweredByAuthor = function(authorId){
    return this.author.id == authorId;
}

module.exports = Answer;