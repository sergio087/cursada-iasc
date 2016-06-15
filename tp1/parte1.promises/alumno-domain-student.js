var Student = function(name, host){
    this.name = name;
    this.id = null;
    this.host = host;
    
    this.signInForum();
}

Student.prototype.signInForum = function(){
    var self = this;
    
    var http = require('http');
    
    var post_data = JSON.stringify(self);
    
    var post_options = {
        host: global.forum_host.host,
        port: global.forum_host.port,
        path: '/student',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(post_data)
        }
    }
    
    var req = http.request(
        post_options,
        function(res){
            
            var res_body = new String();
            
            res.on('data',function(chunk){
                res_body += chunk;
            });
            
            res.on('end', function(){
                res_body = JSON.parse(res_body);
                
                if (res_body.hasOwnProperty('error')){
                    console.error('signInForum | ' + res_body.message);
                } else {
                    self.id = res_body.id;
                    console.info('signInForum | id ' + self.id + ' was assigned.');
                }
            });
        }
    );
    
    req.on('error', function(e) {
      console.error('signInForum | problem with request: ' + e.message);
    });

    req.write(post_data);
    req.end();
}


module.exports = Student;