pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function class (init)
  local c = {}
  c.__index = c
  c._ctr=init
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    self.destroyed=false
    return self
  end
  c.destroy=function(self)
   self.destroyed=true
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,parent)
end

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

node_types={}
nodes={}

rect_x=0
rect_y=40

cls_node_rect=class(function(self,args)
 self.id=args[2]
 nodes[self.id]=self
 self.x=rect_x
 self.y=rect_y
 self.w=20
 rect_x+=25
end)

function cls_node_rect:update()
end

function cls_node_rect:draw()
 rectfill(self.x,self.y,self.x+self.w,self.y+self.w,7)
end

function cls_node_rect:set_value(args)
 local id=args[2]
 local value=args[3]
 if (id==0) self.x=value
 if (id==1) self.y=value
 if (id==2) self.w=value
 return {id,value}
end

node_types[0]=cls_node_rect

function rpc_add_node(args)
 local type=args[1]
 if node_types[type]!=nil then
  local node=node_types[type].init(args)
  return {1,node.id}
 end
 return {0}
end

function rpc_rm_node(args)
end

function rpc_add_connection(args)
end

function rpc_rm_connection(args)
end

function rpc_set_value(args)
 local id=args[1]
 if nodes[id]!=nil then
  nodes[id]:set_value(args)
 end
end

rpc_dispatch[1]=rpc_add_node
rpc_dispatch[2]=rpc_rm_node
rpc_dispatch[3]=rpc_add_connection
rpc_dispatch[4]=rpc_rm_connection
rpc_dispatch[5]=rpc_set_value


function _init()
end

frame=0


function _update()
 dispatch_rpc()
 for node in all(nodes) do
  node:update()
 end
end

function _draw()
 frame+=1
 cls()
 for node in all(nodes) do
  node:draw()
 end
 print(tostr(hello_world_args[1]),64,64,7)
 print(tostr(hello_world_args[2]),64,70,7)
 print(tostr(hello_world_args[3]),64,76,7)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
