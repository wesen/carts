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
