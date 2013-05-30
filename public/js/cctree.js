(function(){
  var CCTree = function(){
  };

  CCTree.prototype.initialize = function(p,q,root,height){
    this.height = height;
    this.tracer = new CTracer(p,q,root);
    this.cctree = set_up(0, root);
  };

  CCTree.prototype.set_up = function(lvl, now){
    if (lvl > this.height) return null;
    var ret = {};
    ret["data"] = now;
    ret["children"] = [];
    this.tracer.now = now
    _.each(this.tracer.ups(), function(v,k,list){
      new_hash = set_up(lvl+1, v)
      if(new_hash) ret["children"].push(new_hash);
    }
    return ret;
  };

})();
