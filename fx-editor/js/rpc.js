const RPC_TYPE_HELLO_WORLD = 0;
const RPC_TYPE_ADD_NODE = 1;
const RPC_TYPE_REMOVE_NODE = 2;
const RPC_TYPE_ADD_CONNECTION = 3;
const RPC_TYPE_REMOVE_CONNECTION = 4;
const RPC_TYPE_SET_VALUE = 5;

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

