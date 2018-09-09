--#include oo
--#include helpers
--#include v2
--#include bbox
--#include hitbox
--#include player
--#include tether
--#include camera
--#include coroutines

lasttime=time()
dt=0
frame=1

function _init()
 player=cls_player.init(v2(10,10))
 cls_tether.init(v2(64,28))
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
 -- parallax background

 camera(p.x,p.y)
 player:draw()
 for tether in all(tethers) do
  tether:draw()
 end

 -- foreground
end
