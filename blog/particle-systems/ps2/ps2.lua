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
 poke(0x5f2d, 1)
 add(sliders,cls_slider.init("count",30,1,40))
 add(sliders,cls_slider.init("spd_factor",0.3,0,3))
 add(sliders,cls_slider.init("lifetime",1,0,5))
 add(sliders,cls_slider.init("spd_scale",0.99,0.93,1.1))
 add(sliders,cls_slider.init("trail_interval",0.1,0.1,.5))
 add(sliders,cls_slider.init("trail_interval_scale",2,1.4,3))
 add(sliders,cls_slider.init("lifetime_scale",2,1,5))
 particles_init()
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
 local mx=stat(32)
 local my=stat(33)
 local mb=band(stat(34),1)==1
 foreach(sliders,function(s) s:update(mx,my,mb) end)
end

function _draw()
 local mx=stat(32)
 local my=stat(33)
 local mb=band(stat(34),1)==1

 cls()
 frame+=1

 tick_crs(draw_crs)
 foreach(parts_1,function(p) p:draw() end)
 foreach(parts_2,function(p) p:draw() end)
 foreach(parts_3,function(p) p:draw() end)
 foreach(sliders,function(s) s:draw(mx,my,mb) end)

 spr(1,mx,my)
 print(tostr(stat(1)),100,100)

 print(tostr(peek(0x5f80)),100,110)
end
