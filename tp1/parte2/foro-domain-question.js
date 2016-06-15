var Sequence = require('./other-sequence.js');
var Answer = require('./foro-domain-answer.js');

var sqQuestion = new Sequence(5000);

var Question = function(author, topic, content, date){
    this.author = author;
    this.topic = topic;
    this.content = content;
    this.answers = [];
    this.date = date || Date.now();
    this.id = sqQuestion.next();
}

Question.prototype.registerAnswer = function(answerAuthor, answerDate){
    var answer = new Answer(this, answerAuthor, answerDate);
    this.answers.push(answer);
    return answer;
}

Question.prototype.isAnswered = function(){
    return this.answers.length > 0;
}

Question.prototype.answer = function(){
    return this.answers[0];
}

module.exports = Question;