cls_node_jitter=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.jitter=0
end)
node_types[9]=cls_node_jitter

function cls_node_jitter:set_value(id,value)
 if (id==0) self:send_value(0,value+mrnd(self.jitter))
 if (id==1) self.jitter=value
end
