--#include helpers
--#include oo
--#include v2
--#include bbox
--#include hitbox
--#include coroutines
--#include globals
--#include enemy

function _init()
 cls_enemy.init(v2(32,64))
 cls_enemy.init(v2(64,32))
 cls_enemy.init(v2(64,96))
 cls_enemy.init(v2(96,64))
end

function _draw()
 frame+=1

 cls()
 if not is_screen_dark then
 end

 tick_crs(draw_crs)
 foreach(actors, function(a) a:draw() end)
 -- player:draw()
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)

 -- player:update()
 foreach(actors, function(a) a:update() end)
end
