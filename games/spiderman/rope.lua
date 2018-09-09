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

player_field_start=384
player_field_end=player_field_start+128
player_field_width=player_field_start
cull_end=player_field_end+player_field_width
cull_start=player_field_start-player_field_width

function cull_elts()
 local off=0
 if player.pos.x>player_field_end then
  off=-128
 elseif player.pos.x<player_field_start then
  off=128
 else
  return
 end

 player.pos.x+=off
 player.prev.x+=off
 main_camera.pos.x+=off

 for tether in all(tethers) do
  tether.pos.x+=off
  if tether.pos.x>cull_end or tether.pos.x<cull_start then
   del(tethers,tether)
  end
 end

 for building in all(buildings) do
  if building.row==row_foreground then
   building.pos.x+=off/0.75
  elseif building.row==row_background then
   building.pos.x+=off/1.5
  else
   building.pos.x+=off
  end
  if building.pos.x>cull_end or building.pos.x<cull_start then
   del(buildings,building)
  end
 end

 if (off==128) add_elts(cull_start,128)
 if (off==-128) add_elts(cull_end,128)
end

function add_elts(off,w)
 local boff=0
 while boff<w do
  local b=v2(boff+off,60+flr(rnd(60)))
  boff+=30+flr(rnd(50))
  cls_building.init(b,row_background)
 end

 boff=0
 while boff<w do
  local b=v2(boff+off,20+flr(rnd(40)))
  boff+=30+flr(rnd(50))
  cls_building.init(b,row_foreground)
 end

 boff=0
 while boff<w do
  local b=v2(boff+off,60+flr(rnd(60)))
  boff+=20+flr(rnd(40))
  cls_tether.init(v2(b.x,128-b.y))
  cls_building.init(b,row_middleground)
 end
end

function _init()
 player=cls_player.init(v2(player_field_start+64,10))

 add_elts(0,player_field_width*2+128)

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
 rectfill(-128,120,player_field_width*2+256,128,13)
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

 camera(0,0)
end
