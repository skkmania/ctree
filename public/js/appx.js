(function(){

  var CTree = Backbone.Model.extend({
    defaults: {
      p: 4,
      q: [0,2,1],
      step: 30
    },
      validate: function(attrs){
        if (attrs.p != attrs.q.length + 1) {
          return "q must have (p - 1) elements";
        }
      }
  });

  var ct1 = new CTree({
    tgt: 123456789
  });

  console.log(ct1.toJSON());
  ct1.set({'p': 5},{ validate: true });
  console.log(ct1.toJSON());
  ct1.set({'p': 5, 'q': [0,3,2,1] },{ validate: true });
  console.log(ct1.toJSON());
  var q = ct1.get('q');
  console.log(q);

  var CTreeView = Backbone.View.extend({
    tagName: 'div',
    className: 'ctree',
    id: 'ct',
    template: _.template( $('#ctree-template').html() ),
    render: function() {
      var template = this.template( this.model.toJSON() );
      this.$el.html(template);
      return this;
    }
  });

  var ct1View = new CTreeView({ model: ct1 });
  console.log(ct1View.render().$el);
  $('body').append(ct1View.render().$el);

})();
