node_types={}
nodes={}

-- BASE NODE ----------------------
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

function cls_node:set_rpc_value(args)
 local id=args[2]
 local value=args[3]
 debug_str="set value "..tostr(id).." value "..tostr(value)
 self:set_value(id,value)
end

function cls_node:set_value(input_num,value)
end

-- RECT NODE ----------------------
rect_x=0
rect_y=40

cls_node_rect=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.x=rect_x
 self.y=rect_y
 self.w=20
 rect_x+=25
end)

function cls_node_rect:draw()
 rectfill(self.x,self.y,self.x+self.w,self.y+self.w,7)
end

function cls_node_rect:set_value(id,value)
 if (id==0) self.x=value
 if (id==1) self.y=value
 if (id==2) self.w=value
 return {id,value}
end

node_types[0]=cls_node_rect

-- SINE NODE ------------------------

cls_node_sine=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.f=1 -- in rotation / second
 self.phase=0
 self.v=0
end)

function cls_node_sine:update()
 local v=sin(time()*self.f+self.phase)
 self.v=v
 self:send_value(0,v*30+30)
end

function cls_node_sine:set_value(id,value)
 if (id==0) self.f=value/20
 if (id==1) self.phase=value/20
end

function cls_node_sine:draw()
 print(tostr(self.v),0,120,7)
 print(tostr(#self.connections),40,120,7)
end

node_types[1]=cls_node_sine

-- NODE RPC -------------------------

function rpc_add_node(args)
 debug_str="add node"
 local type=args[1]
 if node_types[type]!=nil then
  local node=node_types[type].init(args)
  return {1,node.id}
 end
 return {0}
end

function rpc_rm_node(args)
 del(nodes,nodes[args[1]])
end

function rpc_add_connection(args)
 debug_str="add connection"
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