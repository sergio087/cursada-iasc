var Question = function(id, topic, content, date){
    this.id = id;
    this.topic = topic;
    this.content = content;
    this.date_ask = date;
    this.answerId = null;
    this.answerContent = '';
    this.answerCreationDate = null;
    this.answerFulfillmentDate = null;
}


module.exports = Question;