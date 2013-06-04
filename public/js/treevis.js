function skew(x,y, rate){
  var sin = Math.sin(Math.PI*rate);
  var cos = Math.cos(Math.PI*rate);
  return [x*cos + y*sin, x*sin + y*cos];
}
function trans(polar_position,canvas_size,scale,margin,skew_rate,x,y){
  var new_xy = skew(x,y,skew_rate);
  var new_x = new_xy[0];
  var new_y = new_xy[1];
  switch(polar_position){
    case 'top-left':
      return [scale * new_x + margin, scale * new_y + margin]
    case 'top-right':
      return [canvas_size[0] - scale * new_x + margin, scale * new_y + margin]
    case 'bottom-left':
      return [ scale * new_x + margin, canvas_size[1] - scale * new_y + margin]
    case 'bottom-right':
      return [canvas_size[0] - scale * new_x + margin, canvas_size[1] - scale * new_y + margin]
  }
}

var drag = d3.behavior.drag()
  .on("drag", function(d,i) {
    d.x += d3.event.dx
    d.y += d3.event.dy
    d3.select(this).attr("transform", function(d,i){
    return "translate(" + [ d.x,d.y ] + ")"
  })
});

function render_gexf(data, skew_rate){
   var gexf = $.parseXML(data);
   console.log(gexf);
   // nodesからデータを取り出し
   var nodes = d3.select(gexf).selectAll("node")[0];
   var node_values = nodes.map(function(d){
      values = $(d.getElementsByTagName("attvalue")).map(function(i,e){return e.getAttribute('value');});
      return values.toArray();
    });
   var div = d3.select("body").append("div").attr("class", "tooltip").style("opacity", 0);
   var formatTime = d3.time.format("%e %B");
   var canvas_size = [800,600];
   // add element for new tree
   var tree_count = $('#viz_nodes .tree').length
   var $el = $('<div />');
   $el.attr('id','tree_'+tree_count);
   $el.attr('color','#dddddd');
   $el.addClass('tree');
   $('#viz_nodes').append($el);
   //$el.draggable();
debugger;
   // use this element for canvas
   var canvas = d3.select('#'+$el.attr('id')).append('svg').attr('width',canvas_size[0]).attr('height',canvas_size[1]).call(drag);;
   var polar_position = 'top-left';
   var scale = 50;
   var margin = 30;
   window.myposition = [];
   canvas.selectAll("circle").data(node_values).enter()
   .append("circle")
  //   .attr('cx',function(d){ myposition = trans(polar_position,canvas_size,scale,margin,skew_rate,d[3],d[2]); return myposition[0]; })
  //   .attr('cy',function(d){ myposition = trans(polar_position,canvas_size,scale,margin,skew_rate,d[3],d[2]); return myposition[1]; })
     .attr('fill',function(d){ return ((parseInt(d[1])%2==0) ? 'black' : 'pink'); })
     .attr('r', 5)
     .on('mouseover', function(d) {
        div.transition()        
           .duration(100)      
           .style("opacity", .9);      
        div.html(d[4])  
           .style("left", (d3.event.pageX) + "px")     
           .style("top", (d3.event.pageY - 28) + "px");    
        })                  
     .on("mouseout", function(d) {       
        div.transition()        
           .duration(500)      
           .style("opacity", 0);   
       });

   // 数値も付加
   canvas.selectAll("text").data(node_values).enter()
   .append("text")
    // .attr('x',function(d){ myposition = trans(polar_position,canvas_size,scale,margin,skew_rate,d[3],d[2]);return myposition[0]; })
    // .attr('y',function(d){ myposition = trans(polar_position,canvas_size,scale,margin,skew_rate,d[3],d[2]);return myposition[1] + 20; })
     .attr("text-anchor", "middle")  
     .style("font-size", "10px") 
     .text(function(d){ return d[0]; });

   // edgesからデータを取り出し
   var edges = d3.select(gexf).selectAll("edge")[0];
   var edge_values = edges.map(function(d){
      values = $(d).map(function(i,e){return [e.getAttribute('source'),e.getAttribute('target')];});
      return values.toArray();
    });
   canvas.selectAll("path").data(edge_values).enter().append("path")
     .attr('d',function(a, i){
         var src = Number(a[0])-1, tgt = Number(a[1])-1;
         if(node_values[src] && node_values[tgt]){
         var src_x = node_values[src][3];
         var src_y = node_values[src][2];
         var tgt_x = node_values[tgt][3];
         var tgt_y = node_values[tgt][2];
         var src_xy = trans(polar_position,canvas_size,scale,margin,skew_rate,src_x,src_y);
         var tgt_xy = trans(polar_position,canvas_size,scale,margin,skew_rate,tgt_x,tgt_y);
         return 'M'+ src_xy[0] + ',' + src_xy[1] +
         'L'+ tgt_xy[0] + ',' + tgt_xy[1];
         } else {
         return 'M0,0L1,1';
         }
         })
    .attr('stroke', 'black')
    .attr('stroke-width', 1);

   console.log(nodes);
   console.log(edges);
}

$("#request_form").submit(function(){

  $.ajax({
      type: "POST",
      url: "http://wh-my:8888/uptree",
      data: { p: $("#value_p").val(),
              q: $("#value_q").val(),
              root:  $("#value_root").val(),
              level: $("#value_level").val(),
              step:  $("#value_step").val()
            },
      beforeSend: function ( xhr ) {
                    xhr.overrideMimeType("text/plain; charset=x-user-defined");
                  }
   }).done(function ( data ) {
      if( console && console.log ) {
         console.log("Sample of data:", data.slice(0, 100));
      }
      render_gexf(data, $("#value_skew").val());
   });
});
