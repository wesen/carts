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

function cls_node_debug:draw()
 print(tostr(self.v),100,100)
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
end

function cls_node_sine:str()
 return "sine("..tostr(self.f)..","..tostr(self.phase)..")"
end

-- mouse node
cls_node_mouse=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.prev_button=stat(34)
end)
node_types[4]=cls_node_mouse

function cls_node_mouse:update()
 self:send_value(0,stat(32))
 self:send_value(1,stat(33))
 local button=stat(34)
 if (button!=self.prev_button) self:send_value(2,button)
 self.prev_button=button
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
