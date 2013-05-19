  function handleFileSelect(evt) {
    var files = evt.target.files; // FileList object

    // files is a FileList of File objects. List some properties.
    var output = [];
    for (var i = 0, f; f = files[i]; i++) {
      output.push('<li><strong>', escape(f.name), '</strong> (', f.type || 'n/a', ') - ',
                  f.size, ' bytes, last modified: ',
                  f.lastModifiedDate.toLocaleDateString(), '</li>');
    }
    document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>';

    console.log('debug', 'file type is ' + files[0].type);
//    if (files[0].type === 'text/plain') {
        console.log('info', 'file is text/plain.');
        var reader = new FileReader();
        //エラー処理
        reader.onerror = function(e) {
            console.log('error', e.target.error.code);
        }
        //読み込み後の処理
        reader.onload = function(e){
          console.log('info', 'reading file done.');
          console.log(e.target.result);
          //sigInst.parseGexf('http://wh-my:8888/gexf');
          sigInst.parseGexf('http://wh-my:8888/t0517.gexf');
          // Draw the graph :
          sigInst.draw();
        };
        //
        reader.readAsText(files[0], 'UTF-8');
//    }

  }


function init() {


// Instanciate sigma.js and customize rendering :
  sigInst = sigma.init(document.getElementById('sigma-example')).drawingProperties({
                                                                     defaultLabelColor: '#fff',
                                                                     defaultLabelSize: 14,
                                                                     defaultLabelBGColor: '#fff',
                                                                     defaultLabelHoverColor: '#000',
                                                                     labelThreshold: 6,
                                                                     defaultEdgeType: 'curve'
                                                                   }).graphProperties({
                                                                     minNodeSize: 0.5,
                                                                     maxNodeSize: 5,
                                                                     minEdgeSize: 1,
                                                                     maxEdgeSize: 1
                                                                   }).mouseProperties({
                                                                     maxRatio: 32
                                                                   });


}
