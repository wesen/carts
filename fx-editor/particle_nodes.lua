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

cls_node_blast=subclass(cls_node_particles,function(self,args)
 local blast_layer=cls_layer.init()
 blast_layer.emit_interval=nil
 blast_layer.col=7
 blast_layer.min_angle=0
 blast_layer.max_angle=0.5
 blast_layer.default_weight=0
 blast_layer.weight_jitter=0
 blast_layer.fill=true
 blast_layer.default_radius=10
 blast_layer.default_lifetime=0.1
 blast_layer.default_speed_x=0
 blast_layer.default_speed_y=0
 blast_layer.radius_jitter=5
 blast_layer.grow=true
 cls_node_particles._ctr(self,args,blast_layer)
end)
node_types[5]=cls_node_blast

function cls_node_blast:str()
 return "blast"
end

cls_node_rays=subclass(cls_node_particles,function(self,args)
 local layer=cls_layer.init()
 layer.x=64
 layer.y=0
 layer.emit_interval=nil
 layer.col=nil
 layer.cols={8,9,10,10,7}
 layer.min_angle=-0.5
 layer.x_jitter=20
 layer.max_angle=0
 layer.default_weight=2
 layer.weight_jitter=2
 layer.fill=true
 layer.default_radius=2
 layer.default_lifetime=0.5
 layer.lifetime_jitter=0.1
 layer.radius_jitter=1
 layer.default_speed_x=1
 layer.speed_jitter_x=0.3
 layer.default_speed_y=1
 layer.speed_jitter_y=0.3
 layer.trail_duration=0.2
 layer.grow=true
 cls_node_particles._ctr(self,args,layer)
end)
node_types[6]=cls_node_rays

function cls_node_rays:str()
 return "rays"
end

cls_node_dust=subclass(cls_node_particles,function(self,args)
 local dust_layer=cls_layer.init()
 dust_layer.gravity=0.0
 dust_layer.col=nil
 dust_layer.cols={7,10,9,8,2,1}
 dust_layer.emit_interval=nil
 dust_layer.default_lifetime=0.3
 dust_layer.default_speed_x=4
 dust_layer.default_speed_y=4
 dust_layer.default_damping=0.8
 cls_node_particles._ctr(self,args,dust_layer)
end)
node_types[7]=cls_node_dust

function cls_node_dust:set_value(id,value)
 if id==0 and value>0 then
  for i=0,5 do
   self.layer:emit()
  end
 end
 if (id==1) self.layer.x=value
 if (id==2) self.layer.y=value
end

function cls_node_dust:str()
 return "dust"
end
