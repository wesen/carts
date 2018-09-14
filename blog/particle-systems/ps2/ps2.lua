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
 add(sliders,cls_slider.init("slider1",20,20,0.5,0,1))
 add(sliders,cls_slider.init("slider2",20,30,12,2,24))
 add(sliders,cls_slider.init("slider3",20,40,50,0,100))
 add(sliders,cls_slider.init("slider4",20,50,-80,-100,100))
 printh("foobar")
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
end
