--#include oo
--#include coroutines
--#include easing

parts_1={}
parts_2={}
parts_3={}

cls_particle=class(function(self)
 self.x=64
 self.y=64
 self.lifetime=1
 self.t=0
 self.radius=10
end)

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(parts_1,self)
   del(parts_2,self)
   del(parts_3,self)
  end
end

cls_p_band=subclass(cls_particle,function(self)
 cls_particle._ctr(self)
end)
function cls_p_band:draw()
 local v=incirc(1,self.radius,self.t,self.lifetime)
 circ(self.x,self.y,v,7)
end

cls_p_disc=subclass(cls_particle,function(self)
  cls_particle._ctr(self)
  self.lifetime=2
  self.radius=20
end)
function cls_p_disc:draw()
 -- local v=inoutcubic(1,self.radius,self.t,self.lifetime)
 local v=incirc(1,self.radius,self.t,self.lifetime)
 circfill(self.x,self.y,v,12)
end


function _init()
 add_cr(function()
  while true do
   add(parts_1,cls_p_disc.init())
   cr_wait_for(2)
  end
 end)
 add_cr(function()
  while true do
   add(parts_2,cls_p_band.init())
   cr_wait_for(.5)
  end
 end)
end

lasttime=time()
frame=0

function _update60()
 dt=time()-lasttime
 lasttime=time()

 tick_crs(crs)

 foreach(parts_1,function(p) p:update() end)
 foreach(parts_2,function(p) p:update() end)
 foreach(parts_3,function(p) p:update() end)
end

function _draw()
 cls()
 frame+=1

 tick_crs(draw_crs)
 foreach(parts_1,function(p) p:draw() end)
 foreach(parts_2,function(p) p:draw() end)
 foreach(parts_3,function(p) p:draw() end)
end
