const numSocket = new Rete.Socket('Number');
const boolSocket = new Rete.Socket('Boolean');
const triggerSocket = new Rete.Socket('Trigger');

const NODE_TYPE_RECT = 0;
const NODE_TYPE_SINE = 1;
const NODE_TYPE_MULTADD = 2;
const NODE_TYPE_DEBUG = 3;
const NODE_TYPE_MOUSE = 4;
const NODE_TYPE_BLAST = 5;
const NODE_TYPE_RAYS = 6;
const NODE_TYPE_DUST = 7;

class EditorNode extends Rete.Component {
  constructor(name, type) {
    super(name);
    this.type = type;
    this.inputs = {};
    this.outputs = {};
    this.controls = {};
    this.inputNumbers = {};
    this.outputNumbers = {};
    this.defaults = {};
  }

  addInput(key, number, name, socket, defaultValue) {
    this.inputNumbers[key] = number;
    this.inputs[key] = { key, name, socket };
    this.defaults[key] = defaultValue;
    return this;
  }

  addOutput(key, number, name, socket) {
    this.outputNumbers[key] = number;
    this.outputs[key] = { key, name, socket };
    return this;
  }

  addInputControl(key, controlClass) {
    this.inputs[key].controlClass = controlClass;
    return this;
  }

  addControl(key, number, controlClass, defaultValue) {
    this.controls[key] = { key, controlClass };
    this.inputNumbers[key] = number;
    this.defaults[key] = defaultValue;
    return this;
  }

  builder(node) {
    Object.keys(this.inputs).forEach((k) => {
      const input = this.inputs[k];
      const reteInput = new Rete.Input(input.key, input.name, input.socket);
      node.addInput(reteInput);

      if (input.controlClass !== undefined) {
        reteInput.addControl(new input.controlClass(this.editor, input.key));
      }
    });

    Object.keys(this.outputs).forEach((k) => {
      const output = this.outputs[k];
      node.addOutput(new Rete.Output(output.key, output.name, output.socket));
    });

    Object.keys(this.controls).forEach((k) => {
      const control = this.controls[k];
      node.addControl(new control.controlClass(this.editor, control.key));
    });

    node.inputNumbers = this.inputNumbers;
    node.outputNumbers = this.outputNumbers;

    node.data = Object.assign({}, this.defaults, node.data);
    node.type = this.type;

    return node;
  }
}

class DebugNode extends EditorNode {
  constructor() {
    super("Debug", NODE_TYPE_DEBUG);
    this.addInput("value", 0, "Value", numSocket, 0);
  }

}

class MultAddNode extends EditorNode {
  constructor() {
    super("a*x+b", NODE_TYPE_MULTADD);
    this.addInput('value', 0, 'x', numSocket);
    this.addInput('a', 1, 'A', numSocket, 1).addInputControl('a', NumControl);
    this.addInput('b', 2, 'B', numSocket, 0).addInputControl('b', NumControl);
    this.addOutput('val', 0, 'Output', numSocket);
  }
}

class SineNode extends Rete.Component {
  constructor() {
    super("Sine");
  }

  builder(node) {
    const in_freq = new Rete.Input('freq', 'Frequency', numSocket);
    const in_phase = new Rete.Input('phase', 'Phase', numSocket);
    const in_enabled = new Rete.Input('enabled', 'Enabled', boolSocket);
    const in_restart = new Rete.Input('restart', 'Restart', triggerSocket);
    const out_x = new Rete.Output('num', 'Output', numSocket);

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

    node.data = Object.assign({
      freq: 1,
      phase: 0
    }, node.data);

    const result = node
      .addInput(in_freq)
      .addInput(in_phase)
      .addInput(in_enabled)
      .addInput(in_restart)
      .addOutput(out_x);

    return result;
  }
}

class RectNode extends Rete.Component {
  constructor() {
    super("Rect");
  }

  builder(node) {
    const in_x = new Rete.Input('x', 'X', numSocket);
    const in_y = new Rete.Input('y', 'Y', numSocket);
    const in_width = new Rete.Input('width', 'Width', numSocket);

    in_x.addControl(new NumControl(this.editor, 'x'));
    in_y.addControl(new NumControl(this.editor, 'y', false));
    in_width.addControl(new NumControl(this.editor, 'width', false));

    node.inputNumbers = {
      x: 0,
      y: 1,
      width: 2
    };

    node.type = NODE_TYPE_RECT;

    const result = node
      .addInput(in_x)
      .addInput(in_y)
      .addInput(in_width)
    ;

    node.data = Object.assign({
      x: 10,
      y: 10,
      width: 10
    }, node.data);

    return result;
  }

  worker(node, inputs, outputs) {
  }
}

class MouseInputNode extends Rete.Component {
  constructor() {
    super("Mouse");
  }

  builder(node) {
    node.type = NODE_TYPE_MOUSE;
    const out_x = new Rete.Output('x', 'X', numSocket);
    const out_y = new Rete.Output('y', 'Y', numSocket);
    const out_button = new Rete.Output('button', 'Button', numSocket);

    node.outputNumbers = {
      x: 0,
      y: 1,
      button: 2
    };
    const result = node
      .addOutput(out_x)
      .addOutput(out_y)
      .addOutput(out_button);

  }
}

class ParticleNode extends Rete.Component {
  constructor(name,rpcType) {
    super(name);
    this.rpcType = rpcType
  }

  builder(node) {
    node.type = NODE_TYPE_BLAST;

    const in_x = new Rete.Input('x', 'X', numSocket);
    const in_y = new Rete.Input('y', 'Y', numSocket);
    const in_emit = new Rete.Input('emit', 'Emit', numSocket);

    const out_die_x = new Rete.Output('die_x', 'Die X', numSocket);
    const out_die_y = new Rete.Output('die_y', 'Die_Y', numSocket);
    const out_die = new Rete.Output('die', 'Die', numSocket);

    in_x.addControl(new NumControl(this.editor, 'x'));
    in_y.addControl(new NumControl(this.editor, 'y', false));

    node.inputNumbers = {
      emit: 0,
      x: 1,
      y: 2,
    };
    node.controlNumbers = node.inputNumbers;
    node.outputNumbers = {
      die_x: 0,
      die_y: 1,
      die: 2
    };

    node.type = this.rpcType;

    const result = node
      .addInput(in_x)
      .addInput(in_y)
      .addInput(in_emit)
      .addOutput(out_die_x)
      .addOutput(out_die_y)
      .addOutput(out_die);

    node.data = Object.assign({
      x: 10,
      y: 10
    }, node.data);

    return result;
  }
}

class BlastNode extends ParticleNode {
  constructor() {
    super("Blast", NODE_TYPE_BLAST);
  }
}

class RaysNode extends ParticleNode {
  constructor() {
    super("Rays", NODE_TYPE_RAYS);
  }

  builder(node) {
    const result = super.builder(node);

    const in_radius = new Rete.Input('radius', 'Radius', numSocket);
    const in_radius_jitter = new Rete.Input('radius_jitter', 'Radius Jitter', numSocket);
    const in_emit_interval = new Rete.Input('emit_interval', 'Emit Interval', numSocket);
    in_radius.addControl(new NumControl(this.editor, 'radius'));
    in_radius_jitter.addControl(new NumControl(this.editor, 'radius_jitter'));
    in_emit_interval.addControl(new NumControl(this.editor, 'emit_interval'));
    node.inputNumbers = Object.assign({}, node.inputNumbers, {
      radius: 3,
      radius_jitter: 4,
      emit_interval: 5,
    });
    node.controlNumbers = node.inputNumbers;

    node.data = Object.assign({}, {radius: 2, radius_jitter: 0, emit_interval: 0}, node.data);

    return result.addInput(in_radius).addInput(in_radius_jitter).addInput(in_emit_interval);
  }
}

class DustComponent extends ParticleNode {
  constructor() {
    super("Dust", NODE_TYPE_DUST);
  }
}

const components = [
  new RectNode(),
  new SineNode(),
  new MultAddNode(),
  new DebugNode(),
  new MouseInputNode(),
  new BlastNode(),
  new RaysNode(),
  new DustComponent(),
];

