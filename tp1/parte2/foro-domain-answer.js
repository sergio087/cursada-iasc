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

Answer.prototype.isWrittenByAuthor = function(authorId){
    return this.author.id == authorId;
}

Answer.prototype.isFulfilled = function(){
    return this.content.length > 0 && this.fulfillmentDate;
}

Answer.prototype.fulfill = function(content, fulfillmentDate){
    this.content = content;
    this.fulfillmentDate = fulfillmentDate;
}

Answer.prototype.toJSON = function(){
    return JSON.stringify(
        {
            id: this.id,
            author: this.author,
            content: this.content,
            creationDate: this.creationDate,
            fulfillmentDate: this.fulfillmentDate,
            questionId: this.question.id
        }
    );
}

module.exports = Answer;