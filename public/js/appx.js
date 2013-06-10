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
    initialize: function(obj) {
      if (obj) this.model = obj.model;
      this.model.on('destroy', this.remove, this);
    },
    events: {
      "click .delete": "destroy",
      "click .size_minus": "size_minus",
      "click .size_plus": "size_plus",
      "click .trans_minus": "trans_minus",
      "click .trans_plus": "trans_plus",
      "click .updown_minus": "updown_minus",
      "click .updown_plus": "updown_plus",
      "click .op_minus": "op_minus",
      "click .op_plus": "op_plus"
    },
    destroy: function() {
      if (confirm('sure?')){
        this.model.destroy();
      }
    },
    size_minus: function() {
      this.resizeVBox(-0.1);
    },
    size_plus: function() {
      this.resizeVBox(0.1);
    },
    trans_minus: function() {
      this.shiftVBox(0.05, 0);
    },
    trans_plus: function() {
      this.shiftVBox(-0.05, 0);
    },
    updown_minus: function() {
      this.shiftVBox(0, -0.05);
    },
    updown_plus: function() {
      this.shiftVBox(0, 0.05);
    },
    op_minus: function() {
      var opacity = this.$el.css("opacity") || 1.0;
      this.$el.css("opacity",opacity*0.8);
    },
    op_plus: function() {
      var opacity = this.$el.css("opacity") || 1.0;
      opacity = (opacity*1.2 >= 1.0 ? 1.0 : opacity*1.2);
      this.$el.css("opacity",opacity);
    },
    resizeVBox: function(scale) {
      // scale must be in [-1...1]
      //  0 < scale < 1 means making larger
      // -1 < scale < 0 means making smaller
      this.VBox[0] *= (1+scale);
      this.VBox[1] *= (1+scale);
      this.VBox[2] *= (1-scale);
      this.VBox[3] *= (1-scale);
      this.svgCanvas.attr("viewBox", "" + this.VBox[0] + "," + this.VBox[1] + "," + this.VBox[2] + "," + this.VBox[3] );  //svgCanvasタグのviewBox属性を更新
    },
    shiftVBox: function(dx,dy) {
      // dx,dy must be in [-1...1]
      //  0 < dx < 1 means shifting right
      // -1 < dx < 0 means shifting left
      //  0 < dy < 1 means shifting up
      // -1 < dy < 0 means shifting down
      this.VBox[0] += dx*this.VBox[2];
      this.VBox[1] += dy*this.VBox[3];
      this.svgCanvas.attr("viewBox", "" + this.VBox[0] + "," + this.VBox[1] + "," + this.VBox[2] + "," + this.VBox[3] );  //svgCanvasタグのviewBox属性を更新
    },
    remove: function() {
      this.$el.remove();
    },
    template: _.template( $('#ctree-template').html() ),
    render: function() {
      var template = this.template( this.model );
      this.$el.html(template);
      this.svgCanvas = buildTree(this.model.data, this.el,{
         p:this.model.p,
         unit: Math.floor(255 / this.model.p),
         width: 1400,
         nodeRadius: 5,
         fontSize: 12
      });
      this.VBox = _(this.svgCanvas.attr('viewBox').split(',')).map(function(e){return parseInt(e);})
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
debugger;
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
//console.log(ctreeView.render().$el);
//debugger;
    },
    render: function() {
      this.collection.each(function(ctree) {
        var ctreeView = new CTreeView({ model: ctree });
        this.$el.append(ctreeView.render().el);
        ctreeView.setSizeToBBox();
      }, this);
//console.log(ctreeView.render().$el);
//debugger;
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
