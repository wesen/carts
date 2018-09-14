cls_particle=class(function(self)
 self.x=64
 self.y=64
 self.lifetime=1
 self.t=0
 self.radius=15
end)

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(parts_1,self)
   del(parts_2,self)
   del(parts_3,self)
  end
end

band_pal={7,7,7,15,15,10,10,9,9,8,8,8,2,2,2}
cls_p_band=subclass(cls_particle,function(self)
 cls_particle._ctr(self)
end)
function cls_p_band:draw()
 local v=inoutcubic(1,self.radius,self.t,self.lifetime)
 local col=flr(self.t/self.lifetime*#band_pal)
 circ(self.x,self.y,v,band_pal[col])
end

disc_pal={2,2,5,5,8,8,9,9,10,10,10}
cls_p_disc=subclass(cls_particle,function(self)
  cls_particle._ctr(self)
  self.lifetime=2
  self.radius=20
end)
function cls_p_disc:draw()
 -- local v=inoutcubic(1,self.radius,self.t,self.lifetime)
 local v=incirc(1,self.radius,self.t,self.lifetime)
 local col=disc_pal[flr((self.t/self.lifetime)*#disc_pal)]
 circfill(self.x,self.y,v,col)
end

pal={7,10,10,9,9,9,8,8,8,8,4,4,4,2,2,2,2}
cls_p_fly=class(function(self,angle)
 self.x=64
 self.y=64
 self.radius=3
 self.spd_x,self.spd_y=angle2vec(angle)
 self.spd_x*=0.5
 self.spd_y*=0.5
 self.x+=self.spd_x*self.radius
 self.y+=self.spd_y*self.radius
 self.lifetime=slider_vals.lifetime
 self.trail_interval=slider_vals.trail_interval
 self.t_trail=0
 self.t=0
end)

function cls_p_fly:update()
 cls_particle.update(self)
 self.t_trail+=dt
 if self.t_trail>self.trail_interval then
  -- this is stupid, we should just reate particles with no speed and a lifetime
  self.t_trail=0
  local p=copy_table(self)
  local spd_factor=slider_vals.spd_factor
  p.spd_x*=spd_factor
  p.spd_y*=spd_factor
  p.trail_interval*=(self.lifetime*slider_vals.trail_interval_scale)
  p.t_trail=0
  p.lifetime/=slider_vals.lifetime_scale
  p.t/=(self.lifetime*3)
  add(parts_3,p)
 end
 self.x+=self.spd_x
 self.y+=self.spd_y
 self.spd_x*=slider_vals.spd_scale
 self.spd_y*=slider_vals.spd_scale
end

function cls_p_fly:draw()
 local v=flr(self.t/self.lifetime*#pal)
 circ(self.x,self.y,.5,pal[v+1])
end

function particles_init()
 printh("particles init")
 add_cr(function()
  local a=0
  while true do
   cr_wait_for(.4)
  end
 end)

 add_cr(function()
  local a=0
  while true do
   cr_wait_for(slider_vals.lifetime*2)
   a+=0.4
   local cnt=slider_vals.count
   for i=a,cnt+a do
    add(parts_3,cls_p_fly.init(i/cnt))
   end
  end
 end)
 add_cr(function()
  while true do
   -- add(parts_2,cls_p_band.init())
   cr_wait_for(.5)
  end
 end)
end
