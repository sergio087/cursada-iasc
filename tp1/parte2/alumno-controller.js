
var controller = {
    
    question: {
        create: {
            path: '/inbox/question',
            handler: function(req, res){
                console.log("inbox question: " + req.body.id);
                res.end();
            }
        }
    },
    
    answer: {
        create: {
            path: '/inbox/question/:id/answer',
            handler: function(req, res){
                console.log("inbox answer: " + req.body.id + " from question " + req.params.id);
                res.end();
            }
        }
    }
}


module.exports = controller;