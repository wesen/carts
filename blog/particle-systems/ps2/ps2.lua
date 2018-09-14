--#include oo
--#include coroutines
--#include easing
--#include helpers
--#include particles
--#include slider

parts_1={}
parts_2={}
parts_3={}
sliders={}

function _init()
 -- particles_init()
 add(sliders,cls_slider.init("foobar",20,20,0.5,0,1))
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
 foreach(sliders,function(s) s:update() end)
end

function _draw()
 cls()
 frame+=1

 tick_crs(draw_crs)
 foreach(parts_1,function(p) p:draw() end)
 foreach(parts_2,function(p) p:draw() end)
 foreach(parts_3,function(p) p:draw() end)
 foreach(sliders,function(s) s:draw() end)
end
