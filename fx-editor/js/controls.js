function onControlChanged(control) {
  var node = control.getNode();
  var data = control.getData(control.key);
  console.log("onControlChange", control, node, data);

  // for now, we only deal with numbers
  var fractional = Math.floor((data % 1.) * 65536.);
  var integer = Math.floor(data);
  if (integer < 0) {
    integer = 0xffff + integer;
  }
  var args = [
    node.id, node.inputNumbers[control.key],
    integer / 256,
    integer % 256,
    fractional / 256,
    fractional % 256];

  doRpcCall(RPC_TYPE_SET_VALUE, args, function (args) {
    console.log("Set value", args)
  });
}

var VueNumControl = {
  props: ['readonly', 'emitter', 'ikey', 'getData', 'putData', 'control'],
  template: '<div>{{ikey}} <input type="number" :readonly="readonly" :value="value" @input="change($event)"/></div>',
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

var VueColorControl = {
  props: ['readonly', 'emitter', 'ikey', 'getData', 'putData', 'control'],
  template: '<div>{{ikey}} <input type="text" :readonly="readonly" :value="textValue" @input="change($event)"/></div>',
  data() {
    return {
      value: [7],
    }
  },
  computed: {
    textValue: function () {
      return this.value.join(',')
    }
  },
  methods: {
    change(e) {
      this.value = e.target.value.split(/\s*,\s*/).map((s) => +s);
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

var VueBoolControl = {
  props: ['readonly', 'emitter', 'ikey', 'getData', 'putData', 'control'],
  template: '<div>{{ikey}} <input type="checkbox" :readonly="readonly" :checked="value" @input="change($event)"/></div>',
  data() {
    return {
      value: false,
    }
  },
  methods: {
    change(e) {
      console.log("Changed value", e.target.checked, typeof(e.target.value));
      this.value = e.target.checked;
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

class BoolControl extends Rete.Control {
  constructor(emitter, key, readonly, id) {
    super(key);
    this.component = VueBoolControl;
    this.props = {emitter, ikey: key, readonly, control: this};
  }

  setValue(val) {
    this.vueContext.value = val;
  }
}

class ColorControl extends Rete.Control {
  constructor(emitter, key, readonly, id) {
    super(key);
    this.component = VueColorControl;
    this.props = {emitter, ikey: key, readonly, control: this};
  }

  setValue(val) {
    this.vueContext.value = val;
  }
}


class TextControl extends Rete.Control {
  constructor(emitter, key, readonly, type = 'text') {
    super();
    this.emitter = emitter;
    this.key = key;
    this.type = type;
    this.template = `<input type="${type}" :readonly="readonly" :value="value" @input="change($event)"/>`;

    this.scope = {
      value: null,
      readonly,
      change: this.change.bind(this)
    };
  }

  onChange() {
  }

  change(e) {
    this.scope.value = this.type === 'number' ? +e.target.value : e.target.value;
    this.update();
    this.onChange();
  }

  update() {
    if (this.key)
      this.putData(this.key, this.scope.value)
    this.emitter.trigger('process');
    this._alight.scan();
  }

  mounted() {
    this.scope.value = this.getData(this.key) || (this.type === 'number' ? 0 : '...');
    this.update();
  }

  setValue(val) {
    this.scope.value = val;
    this._alight.scan()
  }
}

function handleFileSelect(evt) {
  var files = evt.target.files;

  var output = [];
  for (var i = 0, f; f = files[i]; i++) {
    var reader = new FileReader();

    reader.onload = (function (theFile) {
      return function (e) {
        console.log('e readAsText = ', e);
        console.log('e readAsText target = ', e.target);
        try {
          //handle loading editor here
          editor.fromJSON(JSON.parse(e.target.result))
          console.log('JSON has been loaded to editor');
        } catch (ex) {
          console.log('ex when trying to parse json = ' + ex);
        }
      }
    })(f);
    reader.readAsText(f);
  }

}

function uploadReroute() {
  document.querySelector('#files').click();
}

document.getElementById('files').addEventListener('change', handleFileSelect, false);
document.getElementById("saveLSToFile").addEventListener("click", function () {
  var text = localStorage.module;
  var filename = prompt("Name your file:", "Particle_Effect_01");
  var blob = new Blob([text], {type: "text/plain;charset=utf-8"});
  saveAs(blob, filename + ".json");
  console.log("LocalStorage saved to file")
});
document.getElementById("saveEditorToFile").addEventListener("click", function () {
  var text = JSON.stringify(editor.toJSON());
  var filename = prompt("Name your file:", "Particle_Effect_01");
  var blob = new Blob([text], {type: "text/plain;charset=utf-8"});
  saveAs(blob, filename + ".json");
  console.log("Editor saved to file")
});
