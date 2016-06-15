var Question = function(id, topic, content, date){
    this.id = id;
    this.topic = topic;
    this.content = content;
    this.date_ask = date;
    this.answerContent = '';
    this.answerDate = null;
    this.answerId = null;
}


module.exports = Question;