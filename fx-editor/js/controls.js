function onControlChanged(control) {
  var node = control.getNode();
  var data = control.getData(control.key);
  console.log("onControlChange", control, node, data);

  // for now, we only deal with numbers
  var fractional = Math.floor((data % 1.) * 65536.);
  var integer = Math.floor(data);
  var args = [node.id, node.controlNumbers[control.key], integer / 256, integer % 256, fractional / 256, fractional % 256 ];

  doRpcCall(RPC_TYPE_SET_VALUE, args, function (args) {
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

