var numSocket = new Rete.Socket('Number value');
var boolSocket = new Rete.Socket('Boolean value');
var triggerSocket = new Rete.Socket('Trigger value');

const NODE_TYPE_RECT = 0;
const NODE_TYPE_SINE = 1;
const NODE_TYPE_MULTADD = 2;
const NODE_TYPE_DEBUG = 3;
const NODE_TYPE_MOUSE = 4;

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

    node.data = {
      x: 10,
      y: 10,
      width: 10
    };

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

var components = [
  new RectComponent(),
  new SineComponent(),
  new MultAddComponent(),
  new DebugComponent(),
  new MouseComponent(),
];

