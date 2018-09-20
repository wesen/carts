rpc_dispatch={}

function dispatch_rpc()
 if peek(0x5f80)==0 then
  local type=peek(0x5f81)
  local len=peek(0x5f82)
  local args={}
  for i=1,len do
   args[i]=peek(0x5f82+i)
  end
  if rpc_dispatch[type]!=nil then
   local vals=rpc_dispatch[type](args)
   if vals!=nil then
    poke(0x5f81,#vals)
    for i,v in pairs(vals) do
     poke(0x5f81+i,v)
    end
   end
   poke(0x5f80,2)
  end
 end
end

hello_world_args={0,0,0}

function rpc_hello_world(args)
 for i,v in pairs(args) do
  hello_world_args[i]=v
 end
 return {5,6,7}
end
rpc_dispatch[0]=rpc_hello_world
