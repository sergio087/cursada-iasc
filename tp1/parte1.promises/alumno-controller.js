
var controller = {
    
    inbox: {
        question: {
            path: '/inbox/question',
            handler: function(req, res){
                console.log("inbox question: " + req.body.id);
                res.end();
            }
        },
        
        answer: {
            path: '/inbox/answer',
            handler: function(req, res){
                console.log("inbox answer: " + req.body.id);
                res.end();
            }
        }
    }
}


module.exports = controller;