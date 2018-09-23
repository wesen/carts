--#include oo
--#include helpers

-->8
--#include layer

-->8

-->8

-->8

-->8

-->8

-->8
frame=0
lasttime=time()
dt=0

layers={}

mouse_pos={x=0,y=0}

function _init()

 poke(0x5f2d,1)

 local layer

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
 add(layers,blast_layer)

 layer=cls_layer.init()
 layer.x=64
 layer.y=0
 layer.emit_interval=0.1
 layer.col=nil
 layer.cols={8,9,10,10,7}
 layer.min_angle=-0.5
 -- layer.x_jitter=20
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
 layer.die_cb=function(p)
  local blast=blast_layer:emit(p.x,p.y)
 end
 add(layers,layer)

 local dust_layer=cls_layer.init()
 dust_layer.gravity=0.0
 dust_layer.col=nil
 dust_layer.cols={7,10,9,8,2,1}
 dust_layer.emit_interval=nil
 dust_layer.default_lifetime=0.3
 dust_layer.default_speed_x=4
 dust_layer.default_speed_y=4
 dust_layer.default_damping=0.8
 add(layers,dust_layer)
 blast_layer.emit_cb=function(p)
  for i=0,5 do
   local _p=dust_layer:emit(p.x,p.y)
  end
 end

 layer.target=mouse_pos
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 mouse_pos.x=stat(32)
 mouse_pos.y=stat(33)

 for p in all(layers) do
  p:update()
 end
end

function _draw()
 frame+=1

 cls()
 map(0,0,0,0,16,16)
 rectfill(mouse_pos.x-2,mouse_pos.y-2,mouse_pos.x+2,mouse_pos.y+2,7)
 for p in all(layers) do
  p:draw()
 end

 print(tostr(stat(1)),0, 110,7)
end
