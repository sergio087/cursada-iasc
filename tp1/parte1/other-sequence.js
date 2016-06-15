var Sequence = function(first){
    
    this.current = first || 0
}

Sequence.prototype.next = function(){
    
    this.current ++;
    
    return this.current;
}

module.exports = Sequence;