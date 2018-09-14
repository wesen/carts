--#include oo
--#include coroutines
--#include easing

particles={}

cls_particle=class(function(self)
 self.x=64
 self.y=64
 self.lifetime=2
 self.t=0
 self.radius=20
 add(particles,self)
end)

function cls_particle:update()
 self.t+=dt
 if (self.t>self.lifetime) del(particles,self)
end

function cls_particle:draw()
 local v=self.t/self.lifetime
 circ(self.x,self.y,v*self.radius+1,7)
end

function _init()
 add_cr(function()
  while true do
   cls_particle.init()
   cr_wait_for(2)
  end
 end)
end

lasttime=time()
frame=0

function _update60()
 dt=time()-lasttime
 lasttime=time()

 tick_crs(crs)

 foreach(particles,function(p) p:update() end)
end

function _draw()
 cls()
 frame+=1

 tick_crs(draw_crs)
 foreach(particles,function(p)
   p:draw()
  end)
end
