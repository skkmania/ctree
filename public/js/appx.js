(function(){

  // CTree
  //   Model
  var CTree = Backbone.Model.extend({
    defaults: {
      p: 4,
      q: [0,2,1],
      root: 1,
      step: 10,
      data: null
    },
    initialize: function(p,q,root,step) {
      this.p = p;
      this.q = q;
      this.root = root;
      this.step = step;
      this.data = (new CCTree(p,q,root,step)).cctree;
    },
    validate: function(attrs){
      if (attrs.p != attrs.q.length + 1) {
        return "q must have (p - 1) elements";
      }
    }
  });

  //   View
  var CTreeView = Backbone.View.extend({
    tagName: 'div',
    className: 'ctree',
    initialize: function() {
      this.model.on('destroy', this.remove, this);
    },
    events: {
      "click .delete": "destroy",
      "click .size_minus": "size_minus",
      "click .size_plus": "size_plus",
      "click .op_minus": "op_minus",
      "click .op_plus": "op_plus"
    },
    destroy: function() {
      if (confirm('sure?')){
        this.model.destroy();
      }
    },
    size_minus: function() {
      var opacity = this.$el.css("opacity") || 1.0;
      this.$el.css("opacity",opacity*0.8);
    },
    size_plus: function() {
      var opacity = this.$el.css("opacity") || 1.0;
      opacity = (opacity*1.2 >= 1.0 ? 1.0 : opacity*1.2);
      this.$el.css("opacity",opacity);
    },
    op_minux: function() {
      var opacity = this.$el.css("opacity") || 1.0;
      this.$el.css("opacity",opacity*0.8);
    },
    op_plus: function() {
      var opacity = this.$el.css("opacity") || 1.0;
      opacity = (opacity*1.2 >= 1.0 ? 1.0 : opacity*1.2);
      this.$el.css("opacity",opacity);
    },
    remove: function() {
      this.$el.remove();
    },
    template: _.template( $('#ctree-template').html() ),
    render: function() {
      var template = this.template( this.model.toJSON() );
      this.$el.html(template);
      this.svgCanvas = buildTree(this.model.data, this.el,{
         p:this.model.p,
         unit: Math.floor(255 / this.model.p),
         width: 1400,
         nodeRadius: 5,
         fontSize: 12
      });
      //var css_str = "width:" + svgCanvas.attr("width") + "px ,height:" + svgCanvas.attr("height") + "px";
debugger;
      this.$el.addClass("ui-widget-content");
      //this.$el.css(css_str);
      this.$el.resizable();
      this.$el.draggable();
      return this;
    },
    setSizeToBBox: function(){
      var bbox = this.svgCanvas.node().getBBox();
      this.$el.css({ x: bbox.x, y: bbox.y, width: bbox.width, height: bbox.height });
debugger;
    },
    zoom: function(level) {
      this.projector.scale(this.zoomLevel = level);
    },
    pan: function(x, y) {
      this.projector.translate([
        this.translationOffset[0] += x,
        this.translationOffset[1] += y
      ]);
    },
    refresh: function() {
      d3.select(this.el)
        .selectAll('path')
        .attr('d', this.path);
    }
  });


  // AddTreeView
  var AddTreeView = Backbone.View.extend({
    el: '#addTree',
    events: {
      'submit': 'submit'
    },
    submit: function(e) {
      e.preventDefault();
      var obj = {
        p: parseInt($('#ctree_p').val()),
        q: _.map(($('#ctree_q').val()).replace('[','').replace(']','').split(','), function(e){ return parseInt(e); }),
        root: parseInt($('#ctree_root').val()),
        step: parseInt($('#ctree_step').val())
      };
      var tree = new CTree(obj.p, obj.q, obj.root, obj.step);
      this.collection.add(tree);
    }
  });

  //   Collection
  var CTrees = Backbone.Collection.extend({
    model: CTree
  });

  var CTreesView = Backbone.View.extend({
    el: '#tree-container',
    initialize: function() {
      this.collection.on('add', this.addNewAndRenderIt, this);
    },
    addNewAndRenderIt: function(ctree) {
      var ctreeView = new CTreeView({model: ctree });
      this.$el.append(ctreeView.render().$el);
      ctreeView.setSizeToBBox();
console.log(ctreeView.render().$el);
debugger;
    },
    render: function() {
      this.collection.each(function(ctree) {
        var ctreeView = new CTreeView({ model: ctree });
        this.$el.append(ctreeView.render().el);
        ctreeView.setSizeToBBox();
      }, this);
console.log(ctreeView.render().$el);
debugger;
    }
  });

  //
  // instances
  //
  var ct1 = new CTree(4, [0,2,1], 1, 10);
  console.log(ct1.toJSON());

  var ct1View = new CTreeView({ model: ct1 });
  //console.log(ct1View.render().$el);
  //$('body').append(ct1View.render().el);

  var ctrees = new CTrees([]);

  var ctreesView = new CTreesView({ collection: ctrees });
  ctreesView.addNewAndRenderIt(ct1);

  var addTreeView = new AddTreeView({ collection: ctrees });

})();
