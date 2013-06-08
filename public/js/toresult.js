(function(){

  // TOResult
  //   Model
  var TOResult = Backbone.Model.extend({
    defaults: {
      pattern: [],
      max_move0_len: 0,
      min_of_tgts: 0
    }
    //validate: function(attrs){
    //}
  });

  var tor1 = new TOResult({
    pattern: [8,0,8,0,0,5,0,4,0,0,3],
    max_move0_len: 10,
    min_of_tgts: 2345
  });
  //   View
  var TOResultView = Backbone.View.extend({
    tagName: 'div',
    className: 'toresult',
    template: _.template( $('#toresult-template').html() ),
    render: function() {
      var template = this.template( this.model.toJSON() );
      this.$el.html(template);
      return this;
    }
  });
  var tor1View = new TOResultView({ model: tor1 });
  console.log(tor1View.render().$el);
  $('body').append(tor1View.render().$el);

  //   Collection
  var TOResults = Backbone.Collection.extend({
    model: TOResult
  });
  var toResults = new TOResults([
      {
        pattern: [0,2,0,4,0,2,0,0,1],
        max_move0_len: 3
      },
      {
        pattern: [0,2,0,3,0,1,0,0,1],
        max_move0_len: 2
      },
      {
        pattern: [0,1,0,2,0,1,0,2],
        max_move0_len: 1
      }
      ]);
  console.log(toResults.toJSON());

  var TOResultsView = Backbone.View.extend({
    tagName: 'div',
      render: function() {
        this.collection.each(function(toresult) {
          var toresultView = new TOResultView({ model: toresult });
          this.$el.append(toresultView.render().el);
        }, this);
        return this;
      }
  });
  var toresultsView = new TOResultsView({ collection: toResults });
  $('#toResults').html(toresultsView.render().el);
})();
