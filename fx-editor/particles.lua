cls_layer=class(function(self)
 self.particles={}
 self.x=64
 self.y=64
 self.default_lifetime=1
 self.default_radius=3
 self.default_speed_x=1
 self.default_speed_y=1
 self.gravity=0.1
 self.default_weight=1
 self.fill=false
 self.cols={7}
 self.trail_duration=0
 self.trails={}
 self.die_cb=nil
 self.emit_cb=nil
 self.default_damping=1
 self.radius_f=nil
end)

function cls_layer:emit(x,y)
 if (x==nil) x=self.x
 if (y==nil) y=self.y
 local weight=self.default_weight

 local p={x=x,
          y=y,
          spd_x=self.default_speed_x,
          spd_y=self.default_speed_y,
          t=0,
          cols=self.cols,
          weight=self.default_weight,
          damping=self.default_damping,
          radius=self.default_radius,
          lifetime=self.default_lifetime
         }
 add(self.particles,p)
 if (self.emit_cb!=nil) self.emit_cb(p)
 return p
end

function cls_layer:update()
 for p in all(self.particles) do
  p.x+=p.spd_x
  p.spd_y+=p.weight*self.gravity
  p.y+=p.spd_y
  p.t+=dt
  p.spd_x*=p.damping
  p.spd_y*=p.damping
  if self.trail_duration>0 then
   local v=p.t/p.lifetime
   if (self.radius_f!=nil) v=self.radius_f:compute(v)
   local radius=p.radius*v
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
  local col=p.cols[flr(#p.cols*p.t/p.lifetime)+1]
  local v=p.t/p.lifetime
  if (self.radius_f!=nil) v=self.radius_f:compute(v)
  local radius=v*p.radius
  if self.fill then
   if self.draw_circle then
    circfill(p.x,p.y,radius,col)
   else
    rectfill(p.x-radius/2,p.y-radius/2,p.x+radius/2,p.y+radius/2,col)
   end
  else
   if self.draw_circle then
    circ(p.x,p.y,radius,col)
   else
    rect(p.x-radius/2,p.y-radius/2,p.x+radius/2,p.y+radius/2,col)
   end
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
