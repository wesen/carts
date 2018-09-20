console.log("foobar");


// ------- pico8

const RPC_TYPE_HELLO_WORLD = 0;

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
  rpcCalls.push(new RPCCall(type, args, callback));
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
        rpcCall.fillGpio();
        pico8_gpio[0] = GPIO_DISPATCH_RPC_CALL;
      }
      break;

    case GPIO_DISPATCH_RPC_RESPONSE:
      // RPC call response
      if (rpcCalls.length > 0) {
        rpcCall = rpcCalls.shift();
        var argsLength = pico8_gpio[1];
        var vals = []
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

function onControlChanged(control) {
  console.log("onControlChange", control);
}

var VueNumControl = {
  props: ['readonly', 'emitter', 'ikey', 'getData', 'putData', 'control', 'foobar'],
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
      onControlChanged(this);
    }
  },
  mounted() {
    this.value = this.getData(this.ikey);
  }
};

class NumControl extends Rete.Control {
  constructor(emitter, key, readonly) {
    super(key);
    this.component = VueNumControl;
    this.props = {emitter, ikey: key, readonly, control: this, foobar: 123};
  }

  setValue(val) {
    this.vueContext.value = val;
  }
}

class RectComponent extends Rete.Component {
  constructor() {
    super("Rect");
  }

  builder(node) {
    return node.addControl(new NumControl(this.editor, 'size', false));
  }

  worker(node, inputs, outputs) {
  }
}

var container = document.querySelector('#rete');
var components = [
  new RectComponent()];

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
  });
  editor.on('connectioncreated', async (connection) => {
    console.log('connectioncreated', connection);
  });

  editor.on('nodecreated', async (node) => {
    console.log('nodecreated', node);
  });
  editor.on('noderemoved', async (node) => {
    console.log('noderemoved', node);
  });

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