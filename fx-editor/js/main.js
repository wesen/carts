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

  async function loadModule() {
    console.log("Load module");
    await editor.fromJSON(JSON.parse(localStorage.module));
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

  await loadModule();

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
