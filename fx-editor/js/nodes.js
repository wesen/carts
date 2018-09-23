var numSocket = new Rete.Socket('Number value');
var boolSocket = new Rete.Socket('Boolean value');
var triggerSocket = new Rete.Socket('Trigger value');

const NODE_TYPE_RECT = 0;
const NODE_TYPE_SINE = 1;
const NODE_TYPE_MULTADD = 2;
const NODE_TYPE_DEBUG = 3;
const NODE_TYPE_MOUSE = 4;
const NODE_TYPE_BLAST = 5;
const NODE_TYPE_RAYS = 6;
const NODE_TYPE_DUST = 7;

class DebugComponent extends Rete.Component {
  constructor() {
    super("Debug");
  }

  builder(node) {
    var in_value = new Rete.Input("value", "Value", numSocket);

    node.inputNumbers = {
      value: 0
    };

    node.type = NODE_TYPE_DEBUG;

    return node
      .addInput(in_value);
  }
}

class MultAddComponent extends Rete.Component {
  constructor() {
    super("a*x+b");
  }

  builder(node) {
    var in_value = new Rete.Input('value', 'x', numSocket);
    var in_a = new Rete.Input('a', 'A', numSocket);
    var in_b = new Rete.Input('b', 'B', numSocket);
    in_a.addControl(new NumControl(this.editor, 'a'));
    in_b.addControl(new NumControl(this.editor, 'b'));
    var out_val = new Rete.Output('val', 'Output', numSocket);

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
    var in_freq = new Rete.Input('freq', 'Frequency', numSocket);
    var in_phase = new Rete.Input('phase', 'Phase', numSocket);
    var in_enabled = new Rete.Input('enabled', 'Enabled', boolSocket);
    var in_restart = new Rete.Input('restart', 'Restart', triggerSocket);
    var out_x = new Rete.Output('num', 'Output', numSocket);

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
    var in_x = new Rete.Input('x', 'X', numSocket);
    var in_y = new Rete.Input('y', 'Y', numSocket);
    var in_width = new Rete.Input('width', 'Width', numSocket);

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

class MouseComponent extends Rete.Component {
  constructor() {
    super("Mouse");
  }

  builder(node) {
    node.type = NODE_TYPE_MOUSE;
    var out_x = new Rete.Output('x', 'X', numSocket);
    var out_y = new Rete.Output('y', 'Y', numSocket);
    var out_button = new Rete.Output('button', 'Button', numSocket);

    node.outputNumbers = {
      x: 0,
      y: 1,
      button: 2
    };
    var result = node
      .addOutput(out_x)
      .addOutput(out_y)
      .addOutput(out_button);

  }
}

class ParticleComponent extends Rete.Component {
  constructor(name,rpcType) {
    super(name);
    this.rpcType = rpcType
  }

  builder(node) {
    node.type = NODE_TYPE_BLAST;

    var in_x = new Rete.Input('x', 'X', numSocket);
    var in_y = new Rete.Input('y', 'Y', numSocket);
    var in_emit = new Rete.Input('emit', 'Emit', numSocket);

    var out_die_x = new Rete.Output('die_x', 'Die X', numSocket);
    var out_die_y = new Rete.Output('die_y', 'Die_Y', numSocket);
    var out_die = new Rete.Output('die', 'Die', numSocket);

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

    var result = node
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

class BlastComponent extends ParticleComponent {
  constructor() {
    super("Blast", NODE_TYPE_BLAST);
  }
}

class RaysComponent extends ParticleComponent {
  constructor() {
    super("Rays", NODE_TYPE_RAYS);
  }

  builder(node) {
    var result = super.builder(node);

    var in_radius = new Rete.Input('radius', 'Radius', numSocket);
    var in_radius_jitter = new Rete.Input('radius_jitter', 'Radius Jitter', numSocket);
    var in_emit_interval = new Rete.Input('emit_interval', 'Emit Interval', numSocket);
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

class DustComponent extends ParticleComponent {
  constructor() {
    super("Dust", NODE_TYPE_DUST);
  }
}

var components = [
  new RectComponent(),
  new SineComponent(),
  new MultAddComponent(),
  new DebugComponent(),
  new MouseComponent(),
  new BlastComponent(),
  new RaysComponent(),
  new DustComponent(),
];

