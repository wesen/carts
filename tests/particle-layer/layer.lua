cls_layer=class(function(self)
 self.target=nil
 self.particles={}
 self.emit_interval=.2
 self.t=0
 self.x=64
 self.x_jitter=0
 self.y=64
 self.y_jitter=0
 self.default_lifetime=1
 self.lifetime_jitter=0
 self.default_radius=3
 self.radius_jitter=0
 self.min_angle=0
 self.max_angle=1
 self.default_speed_x=1
 self.speed_jitter_x=0
 self.default_speed_y=1
 self.speed_jitter_y=0
 self.gravity=0.1
 self.default_weight=1
 self.weight_jitter=0
 self.fill=false
 self.col=7
 self.cols=nil
 self.grow=false
 self.trail_duration=0
 self.trails={}
 self.die_cb=nil
 self.emit_cb=nil
 self.default_damping=1
 self.damping_jitter=0
end)

function cls_layer:emit(x,y)
 if x==nil then
  if self.target!=nil then
   x=self.target.x
  else
   x=self.x
  end
 end
 if y==nil then
  if self.target!=nil then
   y=self.target.y
  else
   y=self.y
  end
 end

 local angle=self.min_angle+rnd(self.max_angle-self.min_angle)
 local spd_x=cos(angle)*self.default_speed_x+mrnd(self.speed_jitter_x)
 local spd_y=sin(angle)*self.default_speed_y+mrnd(self.speed_jitter_y)
 local weight=self.default_weight+mrnd(self.weight_jitter)

 local p={x=x+mrnd(self.x_jitter),
          y=y+mrnd(self.y_jitter),
          spd_x=spd_x,
          spd_y=spd_y,
          t=0,
          weight=weight,
          damping=self.default_damping+mrnd(self.damping_jitter),
          radius=self.default_radius+mrnd(self.radius_jitter),
          lifetime=self.default_lifetime+mrnd(self.lifetime_jitter)
         }
 add(self.particles,p)
 if (self.emit_cb!=nil) self.emit_cb(p)
 return p
end

function cls_layer:update()
 self.t+=dt
 if self.emit_interval!=nil and self.t>self.emit_interval then
  self.t=0
  self:emit()
 end
 for p in all(self.particles) do
  p.x+=p.spd_x
  p.spd_y+=p.weight*self.gravity
  p.y+=p.spd_y
  p.t+=dt
  p.spd_x*=p.damping
  p.spd_y*=p.damping
  if self.trail_duration>0 then
   local radius=p.radius*(1-p.t/p.lifetime)
   if (self.grow) radius=p.radius-radius
   add(self.trails,{
    x=p.x,
    y=p.y,
    t=0,
    radius=radius,
    lifetime=self.trail_duration
   })
  end
  if p.t>p.lifetime then
   if (self.die_cb!=nil) self.die_cb(p)
   del(self.particles,p)
  end
 end
 for trail in all(self.trails) do
  trail.t+=dt
  if trail.t>trail.lifetime then
   del(self.trails,trail)
  end
 end
end

function cls_layer:draw()
 for p in all(self.particles) do
  local col=self.col
  if col==nil then
   col=self.cols[flr(#self.cols*p.t/p.lifetime)+1]
  end
  local radius=p.radius*(1-p.t/p.lifetime)
  if (self.grow) radius=p.radius-radius
  if self.fill then
   circfill(p.x,p.y,radius,col)
  else
   circ(p.x,p.y,radius,col)
  end
 end

 for p in all(self.trails) do
  local col=self.col
  if col==nil then
   col=self.cols[flr(#self.cols*p.t/p.lifetime)+1]
  end
  local radius=p.radius
  if self.fill then
   circfill(p.x,p.y,radius,col)
  else
   circ(p.x,p.y,radius,col)
  end
 end
end
