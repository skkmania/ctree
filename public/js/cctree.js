//(function(){
//

  function CTracer(p,q,now){
    this.p = p;
    this.r = p - 1;
    this.q = q;
    this.now = now;
  };

  CTracer.prototype.ups = function(){
    var ret = { 0 : this.now * this.r };
    _.each( _.range(1,this.r), function(e, i, list){
        div = (this.now - this.q[e]) / this.p;
        mod = (this.now - this.q[e]) % this.p;
        if(div == 0){ 
            return false;
        } else {
          if((mod == 0) && ( div * this.p + this.q[div % this.r] == this.now ) ) ret[e] = div;
        }
    }.bind(this));
    return ret;
  };
//
//
//
  function CCTree(p,q,root,height){
    this.height = height;
    this.tracer = new CTracer(p,q,root);
    this.cctree = this.set_up(0, root);
  };

  CCTree.prototype.set_up = function(lvl, now){
    if (lvl > this.height) return null;
    var ret = {};
    ret["name"] = now.toString();
    ret["contents"] = [];
    this.tracer.now = now;
    _.each(this.tracer.ups(), function(v,k,list){
      new_hash = this.set_up(lvl+1, v)
      if(new_hash) ret["contents"].push(new_hash);
    }.bind(this));
    return ret;
  };

//})();
