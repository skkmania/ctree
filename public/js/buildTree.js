
//var ct = new CCTree(5,[0,19,14,9],29,10);  // 4 branch
//ctData = ct.cctree;
//


function visit(parent, visitFn, childrenFn)
{
  if (!parent) return;
  visitFn(parent);
  var children = childrenFn(parent);
  if (children) {
    var count = children.length;
    for (var i = 0; i < count; i++) {
      visit(children[i], visitFn, childrenFn);
    }
  }
} 

function buildTree(ctData, containerName, customOptions)
{
    // build the options object
    var options = $.extend({
        nodeRadius: 5, fontSize: 12
    }, customOptions);
    // Calculate total nodes, max label length
    var totalNodes = 0;
    var maxLabelLength = 0;
    visit(ctData, function(d)
    {
        totalNodes++;
        maxLabelLength =  Math.max(d.name.length, maxLabelLength);
    }, function(d)
    {
        return d.children && d.children.length > 0 ? d.children : null;
    });

    // size of the diagram
    var size = { width:(options.width || $(containerName).outerWidth()), height: totalNodes * 15};

    var width = 0;
    var height = 0;
    var vbox_x = 0;
    var vbox_y = 0;
    var vbox_default_width = vbox_width = 1400;
    var vbox_default_height = vbox_height = 1000;

    var tree = d3.layout.tree()
        .sort(null)
        .size([500,800]);
        //.size([size.height, size.width - maxLabelLength*options.fontSize])
        /*
         * ここは、とりこむデータの子孫属性の名前を指定している。もともとこのソースの作成者は
         * { "name":"abc", "contents":[{...},{...}]}
         * という形式のデータを扱っていた。
         * d3.jsでは子孫属性の名前は children がデフォルトなので、そのようなデータを扱う場合は
         * この部分は必要ない。 
        .children(function(d)
        {
            return (!d.contents || d.contents.length === 0) ? null : d.contents;
        });
        */
    var nodes = tree.nodes(ctData);
    var links = tree.links(nodes);
    /*
        <svg>
            <g class="container" />
        </svg>
     */
    var svgCanvas = d3.select(containerName)
        .append("svg:svg").attr("width", size.width).attr("height", size.height)
        .attr("viewBox", "" + 0 + "," + 0 + "," + size.width + "," + size.height); //viewBox属性を付加
    var layoutRoot = svgCanvas.append("svg:g").attr("class", "container")
                              .attr("transform", "translate(" + maxLabelLength + ",0)");
                             //.attr("transform", "translate(" + 20 + ",0)");

    // Edges between nodes as a <path class="link" />
    var link = d3.svg.diagonal()
        .projection(function(d)
        {
            return [d.y, d.x];
        });

    layoutRoot.selectAll("path.link")
        .data(links)
        .enter()
        .append("svg:path")
        .attr("class", "link")
        .attr("d", link)
    .attr("fill", "none")
    .attr("stroke", function(d)
        {
            var mod = parseInt(d.target.name) % (options.p - 1);
            var scale = (mod + 1) * options.unit;
            var color = "";
            switch(mod%3){
              case 0:
                color =  "rgb(" + 0 + "," + scale + "," + scale + ")";
                break;
              case 1:
                color =  "rgb(" + scale + "," + 0 + "," + scale + ")";
                break;
              case 2:
                color =  "rgb(" + scale + "," + scale + "," + 0 + ")";
                break;
            };
            return color;
        })
    .attr("stroke-width", "2");


    /*
        Nodes as
        <g class="node">
            <circle class="node-dot" />
            <text />
        </g>
     */
    var nodeGroup = layoutRoot.selectAll("g.node")
        .data(nodes)
        .enter()
        .append("svg:g")
        .attr("class", "node")
        .attr("transform", function(d)
        {
            return "translate(" + d.y + "," + d.x + ")";
        });

    nodeGroup.append("svg:circle")
        .attr("class", "node-dot")
        .attr("r", options.nodeRadius)
        .attr("fill", function(d)
        {
            var mod = parseInt(d.name) % options.p;
            var scale = (mod + 1) * options.unit;
            var color = "";
            switch(mod%3){
              case 0:
                color =  "rgb(" + 0 + "," + scale + "," + scale + ")";
                break;
              case 1:
                color =  "rgb(" + scale + "," + 0 + "," + scale + ")";
                break;
              case 2:
                color =  "rgb(" + scale + "," + scale + "," + 0 + ")";
                break;
            };
            return color;
        });

    nodeGroup.append("svg:text")
        .attr("text-anchor", function(d)
        {
            //return d.children ? "end" : "start";
            return "end";
        })
        .attr("dx", function(d)
        {
            var gap = 2 * options.nodeRadius;
            return d.children ? -gap : gap;
        })
        .attr("dy", 3)
        .text(function(d)
        {
            return d.name;
        });

    drag = d3.behavior.drag().on("drag", function(d) {
      vbox_x -= d3.event.dx;
      vbox_y -= d3.event.dy;
      return layoutRoot.attr("translate", "" + vbox_x + " " + vbox_y); //基点の調整。svgタグのtranslate属性を更新
    });
    //svgCanvas.call(drag);

    zoom = d3.behavior.zoom().on("zoom", function(d) {
      var befere_vbox_width, before_vbox_height, d_x, d_y;
      befere_vbox_width = vbox_width;
      before_vbox_height = vbox_height;
      vbox_width = vbox_default_width * d3.event.scale;
      vbox_height = vbox_default_height * d3.event.scale;
      d_x = (befere_vbox_width - vbox_width) / 2;
      d_y = (before_vbox_height - vbox_height) / 2;
      vbox_x += d_x;
      vbox_y += d_y;
      return svgCanvas.attr("viewBox", "" + x + "," + y + "," + width + "," + height);  //svgCanvasタグのviewBox属性を更新
      //return svgCanvas.attr("viewBox", "" + vbox_x + " " + vbox_y + " " + vbox_width + " " + vbox_height);  //svgCanvasタグのviewBox属性を更新
    });
    //svgCanvas.call(zoom);   
    return svgCanvas;
}
