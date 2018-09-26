cls_node_fmultadd=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.a=1
 self.b=0
end)
node_types[16]=cls_node_fmultadd

function cls_node_fmultadd:add_connection(output_num,node_id,input_num)
 cls_node.add_connection(self,output_num,node_id,input_num)
 if (output_num==0) self:send_value(output_num,self)
end

function cls_node_fmultadd:rm_connection(output_num,node_id,input_num)
 if (output_num==0) self:send_value(output_num,nil)
 cls_node.rm_connection(self,output_num,node_id,input_num)
end

function cls_node_fmultadd:set_value(id,value)
 if (id==0) self.a=value
 if (id==1) self.b=value
end

function cls_node_fmultadd:compute(t)
 local res=t*self.a+self.b
 -- cstr(tostr(self.a).."*("..tostr(t)..")+"..tostr(self.b).."="..tostr(res))
 return res
end
