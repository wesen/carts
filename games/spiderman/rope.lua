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

function _init()
 player=cls_player.init(v2(160,10))
 cls_tether.init(v2(204,28))

 cls_building.init(v2(0,80),row_background)
 cls_building.init(v2(90,40),row_background)
 cls_building.init(v2(130,50),row_background)
 cls_building.init(v2(200,90),row_background)

 cls_building.init(v2(40,100),row_middleground)
 cls_building.init(v2(70,80),row_middleground)
 cls_building.init(v2(150,90),row_middleground)

 cls_building.init(v2(20,30),row_foreground)
 cls_building.init(v2(60,40),row_foreground)
 cls_building.init(v2(120,80),row_foreground)

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
