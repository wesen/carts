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

-- from https://www.lexaloffle.com/bbs/?tid=2420

chars=" !\"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

s2c={}
c2s={}
for i=1,95 do
 c=i+31
 s=sub(chars,i,i)
 c2s[c]=s
 s2c[s]=c
end

function chr(i)
 return c2s[i]
end

function ord(s,i)
 return s2c[sub(s,i or 1,i or 1)]
end

function chrs(...)
 local t={...}
 local r=""
 for i=1,#t do
  r=r..c2s[t[i]]
 end
 return r
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

-- base node ----------------------
cls_node=class(function(self,args)
 self.connections={}
 self.id=args[2]
 nodes[self.id]=self
end)

function cls_node:add_connection(output_num,node_id,input_num)
 if (self.connections[output_num]==nil) self.connections[output_num]={}
 add(self.connections[output_num],{node_id=node_id,input_num=input_num})
end

function cls_node:remove_connection(output_num,node_id,input_num)
 local conns=self.connections[output_num]

 if conns!=nil then
  for o in all(conns) do
   if (o.node_id==node_id and o.input_num==input_num) del(conns,o)
  end
 end
end

function cls_node:send_value(output_num,value)
 local conns=self.connections[output_num]

 if conns!=nil then
  for o in all(conns) do
   if nodes[o.node_id]!=nil then
    nodes[o.node_id]:set_value(o.input_num,value)
   else
    del(conns,o)
   end
  end
 end
end

function cls_node:str()
 return "n["..tostr(self.id)..","..tostr(self.type).."]"
end

function cls_node:set_rpc_value(args)
 local id=args[2]
 local value=bor(shl(args[3],8),bor(args[4],bor(shr(args[5],8),shr(args[6],16))))
 debug_str="set value "..tostr(id).." value "..tostr(value).." "..tostr(args[3])..","..tostr(args[4])..","..tostr(args[5])..","..tostr(args[6])
 self:set_value(id,value)
end

function cls_node:set_value(input_num,value)
end

function cls_node:delete()
end

-- debug node ----------

debug_node_cnt=0

cls_node_debug=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.v=0
end)
node_types[3]=cls_node_debug

function cls_node_debug:set_value(id,value)
 if (id==0) self.v=value
end

function cls_node_debug:str()
 return "dbg:"..tostr(self.v)
end

-- multadd node ---------

cls_node_multadd=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.a=1
 self.b=0
end)
node_types[2]=cls_node_multadd

function cls_node_multadd:set_value(id,value)
 if (id==0) self:send_value(0,value*self.a+self.b)
 if (id==1) self.a=value
 if (id==2) self.b=value
end

function cls_node_multadd:str()
 return "madd("..tostr(self.a).."*x+"..tostr(self.b)..")"
end

-- rect node ----------------------
rect_x=0
rect_y=40

cls_node_rect=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.x=rect_x
 self.y=rect_y
 self.w=20
 rect_x+=25
end)
node_types[0]=cls_node_rect

function cls_node_rect:draw()
 rectfill(self.x,self.y,self.x+self.w,self.y+self.w,7)
end

function cls_node_rect:set_value(id,value)
 if (id==0) self.x=value
 if (id==1) self.y=value
 if (id==2) self.w=value
 return {id,value}
end

function cls_node_rect:str()
 return "rect("..tostr(self.x)..","..tostr(self.y)..","..tostr(self.w)..")"
end

-- sine node ------------------------

cls_node_sine=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.f=1 -- in rotation / second
 self.phase=0
 self.v=0
 self.t=0
end)
node_types[1]=cls_node_sine

function cls_node_sine:update()
 self.t+=self.f*dt
 local v=sin(self.t+self.phase)
 self.v=v
 self:send_value(0,v)
end

function cls_node_sine:set_value(id,value)
 if (id==0) self.f=value
 if (id==1) self.phase=value
end

function cls_node_sine:draw()
 print(tostr(self.v),0,120,7)
 print(tostr(#self.connections),40,120,7)
end

function cls_node_sine:str()
 return "sine("..tostr(self.f)..","..tostr(self.phase)..")"
end


-- mouse node
cls_node_mouse=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
end)
node_types[4]=cls_node_mouse

function cls_node_mouse:update()
 self:send_value(0,stat(32))
 self:send_value(1,stat(33))
 self:send_value(2,stat(34))
end

function cls_node_mouse:str()
 return "mouse"
end

-- node rpc -------------------------

function rpc_add_node(args)
 local type=args[1]
 if node_types[type]!=nil then
  local node=node_types[type].init(args)
  node.type=type
  return {1,node.id}
 end
 return {0}
end

function rpc_rm_node(args)
 local id=args[1]
 local node=nodes[id]
 if node!=nil then
  node:delete()
  nodes[id]=nil
 end
end

function rpc_add_connection(args)
 local id=args[1]
 local output_num=args[2]
 local input_node_id=args[3]
 local input_num=args[4]
 if (nodes[id]!=nil) nodes[id]:add_connection(output_num,input_node_id,input_num)
end

function rpc_rm_connection(args)
 local id=args[1]
 local output_num=args[2]
 local input_node_id=args[3]
 local input_num=args[4]
 if (nodes[id]!=nil) nodes[id]:remove_connection(output_num,input_node_id,input_num)
end

function rpc_set_value(args)
 local id=args[1]
 if (nodes[id]!=nil) nodes[id]:set_rpc_value(args)
end

rpc_dispatch[1]=rpc_add_node
rpc_dispatch[2]=rpc_rm_node
rpc_dispatch[3]=rpc_add_connection
rpc_dispatch[4]=rpc_rm_connection
rpc_dispatch[5]=rpc_set_value


function _init()
 poke(0x5f2d,1) 
end

frame=0
dt=0
lasttime=time()

function _update60()
 dt=time()-lasttime
 lasttime=time()
 dispatch_rpc()
 for _,node in pairs(nodes) do
  if (node.update!=nil) node:update()
 end
end

debug_str=""

function _draw()
 frame+=1
 cls()
 for _,node in pairs(nodes) do
  if (node.draw!=nil) node:draw()
 end
 local i=0
 for idx,node in pairs(nodes) do
  print(tostr(idx).."("..tostr(node.id)..") "..node:str(),20,i*6+10)
  i+=1
 end
 print(debug_str,0,0,7)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
