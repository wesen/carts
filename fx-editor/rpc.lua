rpc_dispatch={}

function dispatch_rpc()
 if peek(0x5f80)==0 then
  local type=peek(0x5f81)
  local len=peek(0x5f82)
  local args={}
  for i=1,len do
   args[i]=peek(0x5f82+i)
  end
  debug_str="dispatch type "..tostr(type).." len "..tostr(len).." args "..tostr(#args)
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

function decode_number(args,i)
 return bor(shl(args[i],8),bor(args[i+1],bor(shr(args[i+2],8),shr(args[i+3],16))))
end
