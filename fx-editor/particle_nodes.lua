-- base class for particles

cls_node_particles=subclass(cls_node,function(self,args,layer)
 cls_node._ctr(self,args)
 self.layer=layer
 self.layer.die_cb=function(p)
  self:send_value(0,p.x)
  self:send_value(1,p.y)
  self:send_value(2,1)
 end
end)

function cls_node_particles:update()
 self.layer:update()
end
function cls_node_particles:draw()
 self.layer:draw()
end

function cls_node_particles:set_value(id,value)
 if (id==0 and value>0) self.layer:emit()
 if (id==1) self.layer.x=value
 if (id==2) self.layer.y=value
end

-- generic particles
cls_node_generic_particles=subclass(cls_node_particles,function(self,args)
 local layer=cls_layer.init()
 cls_node_particles._ctr(self,args,layer)
end)
node_types[10]=cls_node_generic_particles

function cls_node_generic_particles:set_value(id,value)
 cls_node_particles.set_value(self,id,value)
 if (id==3) self.layer.default_speed_x=value
 if (id==4) self.layer.default_speed_y=value
 if (id==5) self.layer.default_lifetime=value
 if (id==6) self.layer.default_radius=value
 if (id==7) self.layer.default_weight=value
 if (id==8) self.layer.default_damping=value
 if (id==9) self.layer.fill=value
 if id==10 then
  if type(value)=="number" then
   self.layer.cols={value}
  else
   self.layer.cols=value
  end
 end
 if (id==11) self.layer.draw_circle=value
end

function cls_node_generic_particles:str()
 return "generic"
end

-- emitter node
cls_node_emitter=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.emit_interval=1
 self.t=0
end)
node_types[8]=cls_node_emitter;

function cls_node_emitter:update()
 self.t+=dt
 if self.t>self.emit_interval then
  self:send_value(0,1)
  self.t-=self.emit_interval
 end
end

function cls_node_emitter:set_value(id,value)
 if (id==0) self.emit_interval=value
end

function cls_node_emitter:str()
 return "emitter"
end
