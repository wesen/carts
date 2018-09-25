cls_node_circular_emitter=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.cnt=6
 self.spd=1
end)
node_types[12]=cls_node_circular_emitter

local tick=0

function cls_node_circular_emitter:set_value(id,value)
 if id==0 and value>0 then
  for i=1,self.cnt do
   self:send_value(0,cos(i/self.cnt)*self.spd)
   self:send_value(1,sin(i/self.cnt)*self.spd)
   self:send_value(2,value)
  end
  tick+=1
 else
  if (id==1) self.cnt=value
  if (id==2) self.spd=value
 end
end

cls_node_linear_emitter=subclass(cls_node,function(self,args)
 cls_node._ctr(self,args)
 self.start_x=64
 self.start_y=64
 self.cnt=6
 self.spd_x=0
 self.spd_y=-1
 self.x_spacing=5
 self.y_spacing=0
end)
node_types[13]=cls_node_linear_emitter;

function cls_node_linear_emitter:set_value(id,value)
 if id==0 and value>0 then
  for i=1,self.cnt do
   self:send_value(0,self.start_x+i*self.x_spacing)
   self:send_value(1,self.start_y+i*self.y_spacing)
   self:send_value(2,self.spd_x)
   self:send_value(3,self.spd_y)
   self:send_value(4,value)
  end
 else
  if (id==1) self.cnt=value
  if (id==2) self.start_x=value
  if (id==3) self.start_y=value
  if (id==4) self.spd_x=value
  if (id==5) self.spd_y=value
  if (id==6) self.x_spacing=value
  if (id==7) self.y_spacing=value
 end
end
