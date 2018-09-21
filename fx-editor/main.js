// ------- pico8

const RPC_TYPE_HELLO_WORLD = 0;
const RPC_TYPE_ADD_NODE = 1;
const RPC_TYPE_REMOVE_NODE = 2;
const RPC_TYPE_ADD_CONNECTION = 3;
const RPC_TYPE_REMOVE_CONNECTION = 4;
const RPC_TYPE_SET_VALUE = 5;

const NODE_TYPE_RECT = 0;
const NODE_TYPE_SINE = 1;
const NODE_TYPE_MULTADD = 2;

var NODE_ID = 0;

class RPCCall {
  constructor(type, args, callback) {
    this.type = type;
    this.args = args;
    this.callback = callback;
  }

  fillGpio() {
    pico8_gpio[1] = this.type;
    pico8_gpio[2] = this.args.length;
    for (var i = 0; i < this.args.length; i++) {
      pico8_gpio[3 + i] = this.args[i];
    }
  }
}

var rpcCalls = [];

function doRpcCall(type, args, callback) {
  let rpcCall = new RPCCall(type, args, callback);
  console.log("queueing rpcCall", rpcCall);
  rpcCalls.push(rpcCall);
}

const GPIO_DISPATCH_IDLE = 1;
const GPIO_DISPATCH_RPC_CALL = 0;
const GPIO_DISPATCH_RPC_RESPONSE = 2;

pico8_gpio[0] = GPIO_DISPATCH_IDLE;

function handleGpios() {
  var rpcCall = undefined;

  switch (pico8_gpio[0]) {
    case GPIO_DISPATCH_IDLE:
      // gpios are ours to use
      if (rpcCalls.length > 0) {
        rpcCall = rpcCalls[0];
        console.log("triggering rpc call", rpcCall.type, rpcCall.args);
        rpcCall.fillGpio();
        pico8_gpio[0] = GPIO_DISPATCH_RPC_CALL;
      }
      break;

    case GPIO_DISPATCH_RPC_RESPONSE:
      // RPC call response
      if (rpcCalls.length > 0) {
        rpcCall = rpcCalls.shift();
        var argsLength = pico8_gpio[1];
        var vals = [];
        for (var i = 0; i < argsLength; i++) {
          vals.push(pico8_gpio[2 + i]);
        }
        if (rpcCall.callback !== undefined) {
          rpcCall.callback(vals)
        }
        pico8_gpio[0] = GPIO_DISPATCH_IDLE;
      }
      break;

    default:
      break;
  }

  requestAnimationFrame(handleGpios);
}

requestAnimationFrame(handleGpios);


doRpcCall(RPC_TYPE_HELLO_WORLD, [2, 3, 4], function (vals) {
  console.log("Hello world", vals);
});

// ------- node editor stuff -------

var numSocket = new Rete.Socket('Number value');
var boolSocket = new Rete.Socket('Boolean value');
var triggerSocket = new Rete.Socket('Trigger value');

function onControlChanged(control) {
  var node = control.getNode();
  var data = control.getData(control.key);
  console.log("onControlChange", control, node, data);

  doRpcCall(RPC_TYPE_SET_VALUE, [node.id, node.controlNumbers[control.key], data],
    function (args) {
      console.log("Set value", args)
    });
}

var VueNumControl = {
  props: ['readonly', 'emitter', 'ikey', 'getData', 'putData', 'control'],
  template: '<input type="number" :readonly="readonly" :value="value" @input="change($event)"/>',
  data() {
    return {
      value: 0,
    }
  },
  methods: {
    change(e) {
      this.value = +e.target.value;
      this.update();
    },
    update() {
      if (this.ikey) {
        this.putData(this.ikey, this.value)
      }
      this.emitter.trigger('process');
      onControlChanged(this.control);
    }
  },
  mounted() {
    this.value = this.getData(this.ikey);
  }
};

class NumControl extends Rete.Control {
  constructor(emitter, key, readonly, id) {
    super(key);
    this.component = VueNumControl;
    this.props = {emitter, ikey: key, readonly, control: this};
  }

  setValue(val) {
    this.vueContext.value = val;
  }
}

class MultAddComponent extends Rete.Component {
  constructor() {
    super("MultAdd");
  }

  builder(node) {
    var in_value = new Rete.Input('value', 'Number', numSocket);
    var in_a = new Rete.Input('a', 'Number', numSocket);
    var in_b = new Rete.Input('b', 'Number', numSocket);
    in_a.addControl(new NumControl(this.editor, 'a'));
    in_b.addControl(new NumControl(this.editor, 'b'));
    var out_val = new Rete.Output('val', 'Number', numSocket);

    node.inputNumbers = node.controlNumbers = {
      value: 0,
      a: 1,
      b: 2,
    };
    node.outputNumbers = {
      val: 0,
    };

    node.type = NODE_TYPE_MULTADD;

    return node
      .addInput(in_value)
      .addInput(in_a)
      .addInput(in_b)
      .addOutput(out_val);
  }
}

class SineComponent extends Rete.Component {
  constructor() {
    super("Sine");
  }

  builder(node) {
    var in_freq = new Rete.Input('freq', 'Number', numSocket);
    var in_phase = new Rete.Input('phase', 'Number', numSocket);
    var in_enabled = new Rete.Input('enabled', 'Boolean', boolSocket);
    var in_restart = new Rete.Input('restart', 'Trigger', triggerSocket);
    var out_x = new Rete.Output('num', 'Number', numSocket);

    in_freq.addControl(new NumControl(this.editor, 'freq'));
    in_phase.addControl(new NumControl(this.editor, 'phase'));

    node.inputNumbers = {
      freq: 0,
      phase: 1,
      enabled: 2,
      restart: 3,
    };
    node.outputNumbers = {
      num: 0
    };
    node.controlNumbers = node.inputNumbers;

    node.type = NODE_TYPE_SINE;

    var result = node
      .addInput(in_freq)
      .addInput(in_phase)
      .addInput(in_enabled)
      .addInput(in_restart)
      .addOutput(out_x);

    return result;
  }
}

class RectComponent extends Rete.Component {
  constructor() {
    super("Rect");
  }

  builder(node) {
    var in_x = new Rete.Input('x', 'Number', numSocket);
    var in_y = new Rete.Input('y', 'Number', numSocket);
    var in_width = new Rete.Input('width', 'Number', numSocket);

    in_x.addControl(new NumControl(this.editor, 'x'));
    in_y.addControl(new NumControl(this.editor, 'y', false));
    in_width.addControl(new NumControl(this.editor, 'width', false));

    node.inputNumbers = {
      x: 0,
      y: 1,
      width: 2
    };
    node.controlNumbers = node.inputNumbers;

    node.type = NODE_TYPE_RECT;

    var result = node
      .addInput(in_x)
      .addInput(in_y)
      .addInput(in_width)
    ;


    return result;
  }

  worker(node, inputs, outputs) {
  }
}

var container = document.querySelector('#rete');
var components = [
  new RectComponent(),
  new SineComponent(),
  new MultAddComponent()
];

var editor = new Rete.NodeEditor('demo@0.1.0', container);
console.log("editor", editor);
editor.use(ConnectionPlugin, {curvature: 0.4});
editor.use(VueRenderPlugin);
editor.use(ContextMenuPlugin);
editor.use(AreaPlugin);

function fitPico8() {
  const {container} = editor.view;
  const width = container.parentElement.clientWidth;
  const height = Math.max(0, container.parentElement.clientHeight - 550);

  container.style.width = width + 'px';
  container.style.height = height + 'px';
}

window.addEventListener('resize', fitPico8);

var engine = new Rete.Engine('demo@0.1.0');

components.map(c => {
  editor.register(c);
  engine.register(c);
})
;

(async () => {
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
      console.log("node created in pico8", args);
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

  var n3 = await components[2].createNode({a: 16*10, b: 0});
  n3.position = [200,200];
  editor.addNode(n3);

  editor.on('process nodecreated noderemoved connectioncreated connectionremoved', async () => {
    console.log("process")
    await engine.abort();
    await engine.process(editor.toJSON());
  })
  ;

  editor.view.resize();
  fitPico8();
  AreaPlugin.zoomAt(editor);
  editor.trigger('process');
})();