const NODE_TYPE_RECT = 0;
const NODE_TYPE_SINE = 1;
const NODE_TYPE_MULTADD = 2;
const NODE_TYPE_DEBUG = 3;

var NODE_ID = 0;

// ------- node editor stuff -------

var container = document.querySelector('#rete');
var editor = new Rete.NodeEditor('demo@0.1.0', container);
console.log("editor", editor);
editor.use(ConnectionPlugin, {curvature: 0.4});
editor.use(VueRenderPlugin);
editor.use(ContextMenuPlugin);
editor.use(AreaPlugin);

function fitPico8() {
  const {container} = editor.view;
  const width = container.parentElement.clientWidth;
  const height = Math.max(0, container.parentElement.clientHeight);

  container.style.width = width + 'px';
  container.style.height = height + 'px';
}

window.addEventListener('resize', fitPico8);

var engine = new Rete.Engine('demo@0.1.0');

components.map(c => {
  editor.register(c);
  engine.register(c);
});

(async () => {
  function saveModule() {
    console.log("Add module");
    localStorage.module = JSON.stringify(editor.toJSON());
  }

  function loadModule() {
    console.log("Load module");
    editor.fromJSON(JSON.parse(localStorage.module));
  }

  function openModule(m) {
    console.log("Open module");
  }

  var modules = [];

  alight("#modules", { modules, saveModule, openModule, loadModule });

  editor.on('connectionremoved', async (connection) => {
    console.log('connectionremoved', connection);

    var inputNode = connection.input.node;
    var inputKey = connection.input.key;
    var inputNumber = inputNode.inputNumbers[inputKey];

    var outputNode = connection.output.node;
    var outputKey = connection.output.key;
    var outputNumber = outputNode.outputNumbers[outputKey];

    doRpcCall(RPC_TYPE_REMOVE_CONNECTION, [outputNode.id, outputNumber, inputNode.id, inputNumber], function (args) {
      console.log("connection created in pico8", args);
    });
  });

  editor.on('connectioncreated', async (connection) => {
    console.log('connectioncreated', connection);
    var inputNode = connection.input.node;
    var inputKey = connection.input.key;
    var inputNumber = inputNode.inputNumbers[inputKey];

    var outputNode = connection.output.node;
    var outputKey = connection.output.key;
    var outputNumber = outputNode.outputNumbers[outputKey];

    doRpcCall(RPC_TYPE_ADD_CONNECTION, [outputNode.id, outputNumber, inputNode.id, inputNumber], function (args) {
      console.log("connection created in pico8", args);
    });
  });

  editor.on('nodecreated', async (node) => {
    console.log('nodecreated', node, node.type, node.id);
    doRpcCall(RPC_TYPE_ADD_NODE, [node.type, node.id], function (args) {
      console.log("node created in pico8", node, args);
      node.inputs.forEach((input) => {
        console.log("input", input);
        console.log("control", input.control);
        if (input.control !== undefined && input.control !== null) {
          onControlChanged(input.control);
        }
      });
      node.controls.forEach((control) => {
        console.log("control", control);
      });
    });
    node.controls.forEach(onControlChanged);
  });

  editor.on('noderemoved', async (node) => {
    console.log('noderemoved', node);
    doRpcCall(RPC_TYPE_REMOVE_NODE, [node.id], function (args) {
      console.log("node removed in pico8", args);
    });
  });

  var n1 = await components[0].createNode({x: 10, y: 20, width: 10});
  n1.position = [400, 200];
  editor.addNode(n1);

  var n2 = await components[1].createNode({freq: 10, phase: 20});
  n2.position = [80, 200];
  editor.addNode(n2);

  var n3 = await components[2].createNode({a: 16 * 10, b: 0});
  n3.position = [200, 200];
  editor.addNode(n3);

  var n4 = await components[3].createNode({x: 0, y: 12});
  n4.position = [300, 200];
  editor.addNode(n4);

  editor.on('process nodecreated noderemoved connectioncreated connectionremoved', async () => {
    await engine.abort();
    await engine.process(editor.toJSON());
  })
  ;

  editor.view.resize();
  fitPico8();
  AreaPlugin.zoomAt(editor);
  editor.trigger('process');
})();

// save to text

function saveFile(filename, data) {
  var blob = new Blob([data], {type: 'text/csv'});
  if(window.navigator.msSaveOrOpenBlob) {
    window.navigator.msSaveBlob(blob, filename);
  }
  else{
    var elem = window.document.createElement('a');
    elem.href = window.URL.createObjectURL(blob);
    elem.download = filename;
    document.body.appendChild(elem);
    elem.click();
    document.body.removeChild(elem);
  }
}
