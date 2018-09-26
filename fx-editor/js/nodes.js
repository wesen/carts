const numSocket = new Rete.Socket('Number');
const boolSocket = new Rete.Socket('Boolean');
const triggerSocket = new Rete.Socket('Trigger');
const functionSocket = new Rete.Socket('Function');
const colorSocket = new Rete.Socket('Color');

const NODE_TYPE_RECT = 0;
const NODE_TYPE_SINE = 1;
const NODE_TYPE_MULTADD = 2;
const NODE_TYPE_DEBUG = 3;
const NODE_TYPE_MOUSE = 4;
// const NODE_TYPE_BLAST = 5;
// const NODE_TYPE_RAYS = 6;
// const NODE_TYPE_DUST = 7;
const NODE_TYPE_EMITTER = 8;
const NODE_TYPE_JITTER = 9;
const NODE_TYPE_GENERIC_PARTICLES = 10;
const NODE_TYPE_FUNCTION_MULTADD = 11;
const NODE_TYPE_CIRCULAR_EMITTER = 12;
const NODE_TYPE_LINE_EMITTER = 13;
const NODE_TYPE_LATCH=14;
const NODE_TYPE_ORDER=15;

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
    this.inputs[key] = {key, name, socket};
    this.defaults[key] = defaultValue;
    return this;
  }

  addOutput(key, number, name, socket) {
    this.outputNumbers[key] = number;
    this.outputs[key] = {key, name, socket};
    return this;
  }

  addInputControl(key, controlClass) {
    this.inputs[key].controlClass = controlClass;
    return this;
  }

  addControl(key, number, controlClass, defaultValue) {
    this.controls[key] = {key, controlClass};
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

class SineNode extends EditorNode {
  constructor() {
    super("Sine", NODE_TYPE_SINE);
    this.addInput('freq', 0, 'Frequency', numSocket, 1)
      .addInputControl('freq', NumControl)
      .addInput('phase', 1, 'Phase', numSocket, 0)
      .addInputControl('phase', NumControl)
      .addInput('enabled', 2, 'Enabled', boolSocket, true)
      .addInput('restart', 3, 'Restart', triggerSocket)
      .addOutput('num', 0, 'Output', numSocket);
  }
}

class RectNode extends EditorNode {
  constructor() {
    super("Rect", NODE_TYPE_RECT);
    this.addInput('x', 0, 'X', numSocket, 10)
      .addInputControl('x', NumControl)
      .addInput('y', 1, 'Y', numSocket, 10)
      .addInputControl('y', NumControl)
      .addInput('w', 2, 'Width', numSocket, 10)
      .addInputControl('w', NumControl);
  }
}

class MouseInputNode extends EditorNode {
  constructor() {
    super("Mouse", NODE_TYPE_MOUSE);
    this.addOutput('x', 0, 'X', numSocket)
      .addOutput('y', 1, 'Y', numSocket)
      .addOutput('button', 2, 'Button', triggerSocket);
  }
}

class ParticleNode extends EditorNode {
  constructor(name, rpcType) {
    super(name, rpcType);
    this.addInput('x', 1, 'X', numSocket, 64)
      .addInputControl('x', NumControl)
      .addInput('y', 2, 'Y', numSocket, 64)
      .addInputControl('y', NumControl)
      .addInput('emit', 0, 'Emit', triggerSocket)
      .addOutput('die_x', 0, 'Die X', numSocket)
      .addOutput('die_y', 1, 'Die Y', numSocket)
      .addOutput('die', 2, 'Die', triggerSocket)
  }
}

class EmitterNode extends EditorNode {
  constructor() {
    super("Emitter", NODE_TYPE_EMITTER);
    this.addInput('interval', 0, 'Interval', numSocket, 0.5)
      .addInputControl('interval', NumControl)
      .addOutput('emit', 0, 'Emit', triggerSocket);
  }
}

class JitterNode extends EditorNode {
  constructor() {
    super("Jitter", NODE_TYPE_JITTER);
    this.addInput("value", 0, 'Value', numSocket)
      .addInput("jitter", 1, "Jitter", numSocket, 0)
      .addInputControl('jitter', NumControl)
      .addOutput('value', 0, 'Value', numSocket);
  }
}

class GenericParticleNode extends ParticleNode {
  constructor() {
    super("Generic Particles", NODE_TYPE_GENERIC_PARTICLES);
    this
      .addInput('spd_x', 3, 'Speed X', numSocket, 0)
      .addInputControl('spd_x', NumControl)
      .addInput('spd_y', 4, 'Speed Y', numSocket, 0)
      .addInputControl('spd_y', NumControl)
      .addInput('lifetime', 5, 'Lifetime', numSocket, 1)
      .addInputControl('lifetime', NumControl)
      .addInput('radius', 6, 'Radius', numSocket, 2)
      .addInputControl('radius', NumControl)
      .addInput('weight', 7, 'Weight', numSocket, 0)
      .addInputControl('weight', NumControl)
      .addInput('damping', 8, 'Damping', numSocket, 1)
      .addInputControl('damping', NumControl)
      .addInput('fill', 9, 'Fill', boolSocket, 0)
      .addInputControl('fill', BoolControl)
      .addInput('color', 10, 'Color', colorSocket, [7])
      .addInputControl('color', ColorControl)
      .addInput('circle', 11, 'Circle', boolSocket, true)
      .addInputControl('circle', BoolControl)
    ;
  }
}

class CircularEmitterNode extends EditorNode {
  constructor() {
    super("CircularEmitterNode", NODE_TYPE_CIRCULAR_EMITTER);
    this.addInput('emit', 0, 'Emit', triggerSocket)
      .addInput('cnt', 1, 'Count', numSocket, 6)
      .addInputControl('cnt', NumControl)
      .addInput('spd', 2, 'Speed', numSocket, 1)
      .addInputControl('spd', NumControl)
      .addOutput('spd_x', 0, 'X Speed', numSocket)
      .addOutput('spd_y', 1, 'Y Speed', numSocket)
      .addOutput('emit', 2, 'Emit', triggerSocket);
  }
}

class LinearEmitterNode extends EditorNode {
  constructor() {
    super("Linear Emitter", NODE_TYPE_LINE_EMITTER);
    this.addInput('emit', 0, 'Emit', triggerSocket)
      .addInput('cnt', 1, 'Count', numSocket, 6)
      .addInputControl('cnt', NumControl)
      .addInput('start_x', 2, 'X Start', numSocket, 1)
      .addInputControl('start_x', NumControl)
      .addInput('start_y', 3, 'Y Start', numSocket, 100)
      .addInputControl('start_y', NumControl)

      .addInput('spd_x', 4, 'X Speed', numSocket, 0)
      .addInputControl('spd_x', NumControl)
      .addInput('spd_y', 5, 'Y Speed', numSocket, -1)
      .addInputControl('spd_y', NumControl)

      .addInput('x_spacing', 6, 'X Spacing', numSocket, 5)
      .addInputControl('x_spacing', NumControl)
      .addInput('y_spacing', 7, 'Y Spacing', numSocket, 0)
      .addInputControl('y_spacing', NumControl)

      .addOutput('x', 0, 'X', numSocket)
      .addOutput('y', 1, 'Y', numSocket)
      .addOutput('spd_x', 2, 'X Speed', numSocket)
      .addOutput('spd_y', 3, 'Y Speed', numSocket)
      .addOutput('emit', 4, 'Emit', triggerSocket);
  }
}

class LatchNode extends EditorNode {
  constructor() {
    super("Latch", NODE_TYPE_LATCH);
    this.addInput("v", 0, "Value", numSocket, 0)
      .addInputControl('v', NumControl)
      .addInput("trigger", 1, 'Trigger', triggerSocket)
      .addOutput('value', 0, 'Value', numSocket);
  }
}

class OrderNode extends EditorNode {
  constructor() {
    super("Order", NODE_TYPE_ORDER);
    this
      .addInput("trigger", 0, 'Trigger', triggerSocket)
      .addOutput('emit1', 0, 'Emit1', triggerSocket)
      .addOutput('emit2', 1, 'Emit2', triggerSocket)
      .addOutput('emit3', 2, 'Emit3', triggerSocket)
      .addOutput('emit4', 3, 'Emit4', triggerSocket)
      .addOutput('emit5', 4, 'Emit5', triggerSocket);
  }
}

const components = [
  new RectNode(),
  new SineNode(),
  new MultAddNode(),
  new DebugNode(),
  new MouseInputNode(),
  new EmitterNode(),
  new JitterNode(),
  new GenericParticleNode(),
  new CircularEmitterNode(),
  new LinearEmitterNode(),
  new LatchNode(),
  new OrderNode(),
];

