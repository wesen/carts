--#include oo
--#include helpers
--#include v2
--#include bbox
--#include hitbox
--#include player
--#include tether
--#include camera
--#include coroutines
--#include building

lasttime=time()
dt=0
frame=1
tethers={}

function cull_elts()
 local off=0
 if player.pos.x>256 then
  off=-128
 elseif player.pos.x<128 then
  off=128
 else
  return
 end

 player.pos.x+=off
 player.prev.x+=off
 main_camera.pos.x+=off

 for tether in all(tethers) do
  tether.pos.x+=off
  if tether.pos.x>384 or tether.pos.x<0 then
   del(tethers,tether)
  end
 end

 for building in all(buildings) do
  building.pos.x+=off
  if building.pos.x>384 or building.pos.x<0 then
   del(buildings,building)
  end
 end

 if (off==128) add_elts(0)
 if (off==-128) add_elts(256)
end

function add_elts(off)
 -- for i=1,5+flr(rnd(5)) do
 --  cls_building.init(v2(flr(rnd(128))+off,60+flr(rnd(60))),row_background)
 -- end
 local boff=0
 for i=1,3+flr(rnd(5)) do
  local b=v2(boff+off,60+flr(rnd(60)))
  boff+=30+flr(rnd(50))
  if b.x<off+128 then
   cls_tether.init(v2(b.x,128-b.y))
   cls_building.init(b,row_middleground)
  end
 end
 -- for i=1,5+flr(rnd(5)) do
 --  cls_building.init(v2(flr(rnd(128))+off,20+flr(rnd(40))),row_foreground)
 -- end
end

function _init()
 player=cls_player.init(v2(160,10))

 add_elts(0)
 add_elts(128)
 add_elts(256)

 main_camera=cls_camera.init()
 main_camera:set_target(player)
end

function _update()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)

 player:update()
 for tether in all(tethers) do
  tether:update()
 end

 main_camera:update()

 cull_elts()
end

function _draw()
 frame+=1

 cls()
 local p=main_camera:compute_position()
 camera(p.x/1.5,p.y/1.5)
 for building in all(buildings) do
  if (building.row==row_background) building:draw()
 end
 -- parallax background

 camera(p.x,p.y)
 for building in all(buildings) do
  if (building.row==row_middleground) building:draw()
 end
 for tether in all(tethers) do
  tether:draw()
 end
 player:draw()

 -- foreground
 camera(p.x/0.75,p.y/0.75)
 for building in all(buildings) do
  if (building.row==row_foreground) building:draw()
 end
end
