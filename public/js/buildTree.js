/**
 * Created by JetBrains RubyMine.
 * User: pavanpodila
 * Date: 7/17/11
 * Time: 4:30 PM
 * To change this template use File | Settings | File Templates.
 */

//var ct = new CCTree(5,[0,19,14,9],29,10);  // 4 branch
//var ct = new CCTree(6,[0,34,28,22,16],10,10); // 5 branch
//var ct = new CCTree(7,[0,41,34,27,20,13],1812,10); // 6 branch
//var ct = new CCTree(8,[0,55,47,39,31,23,15],175,10); // 7 branch
//var ct = new CCTree(9,[0,71,62,53,44,35,26,17],1,10); // 8 branch
//var ct = new CCTree(10,[0,89,79,69,59,49,39,29,19],1,10); // 9 branch
//var ct = new CCTree(11,[0,109,98,87,76,65,54,43,32,21],1,10); // 10 branch
//var ct = new CCTree(11,[0,109,98,87,76,65,54,43,32,31],1,10); // 9 branch
var ct = new CCTree(11,[0,109,98,87,76,65,44,43,42,31],1,10); // 7 branch
var ctData = ct.cctree;
var treeData = {
    name: "/",
    contents: [
        {
            name: "Applications",
            contents: [
                { name: "Mail.app" },
                { name: "iPhoto.app" },
                { name: "Keynote.app" },
                { name: "iTunes.app" },
                { name: "XCode.app" },
                { name: "Numbers.app" },
                { name: "Pages.app" }
            ]
        },
        {
            name: "System",
            contents: []
        },
        {
            name: "Library",
            contents: [
                {
                    name: "Application Support",
                    contents: [
                        { name: "Adobe" },
                        { name: "Apple" },
                        { name: "Google" },
                        { name: "Microsoft" }
                    ]
                },
                {
                    name: "Languages",
                    contents: [
                        { name: "Ruby" },
                        { name: "Python" },
                        { name: "Javascript" },
                        { name: "C#" }
                    ]
                },
                {
                    name: "Developer",
                    contents: [
                        { name: "4.2" },
                        { name: "4.3" },
                        { name: "5.0" },
                        { name: "Documentation" }
                    ]
                }
            ]
        },
        {
            name: "opt",
            contents: []
        },
        {
            name: "Users",
            contents: [
                { name: "pavanpodila" },
                { name: "admin" },
                { name: "test-user" }
            ]
        }
    ]
};

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

function buildTree(containerName, customOptions)
{
    // build the options object
    var options = $.extend({
        nodeRadius: 5, fontSize: 12
    }, customOptions);

    
    // Calculate total nodes, max label length
    var totalNodes = 0;
    var maxLabelLength = 0;
    //visit(treeData, function(d)
    visit(ctData, function(d)
    {
        totalNodes++;
        maxLabelLength = Math.max(d.name.length, maxLabelLength);
    }, function(d)
    {
        return d.contents && d.contents.length > 0 ? d.contents : null;
    });

    // size of the diagram
    var size = { width:$(containerName).outerWidth(), height: totalNodes * 15};

    var tree = d3.layout.tree()
        .sort(null)
        .size([size.height, size.width - maxLabelLength*options.fontSize])
        .children(function(d)
        {
            return (!d.contents || d.contents.length === 0) ? null : d.contents;
        });

    //var nodes = tree.nodes(treeData);
    var nodes = tree.nodes(ctData);
    var links = tree.links(nodes);

    
    /*
        <svg>
            <g class="container" />
        </svg>
     */
    var layoutRoot = d3.select(containerName)
        .append("svg:svg").attr("width", size.width).attr("height", size.height)
        .append("svg:g")
        .attr("class", "container")
        .attr("transform", "translate(" + maxLabelLength + ",0)");


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
        .attr("d", link);


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
        .attr("r", options.nodeRadius);

    nodeGroup.append("svg:text")
        .attr("text-anchor", function(d)
        {
            return d.children ? "end" : "start";
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

}
