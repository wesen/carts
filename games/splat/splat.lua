--#include helpers
--#include oo
--#include v2
--#include bbox
--#include hitbox
--#include globals
--#include coroutines
--#include enemy
--#include player
--#include enemy-manager


function _init()
 player=cls_player.init(v2(64,64))
 enemy_manager=cls_enemy_manager.init()
 enemy_manager:add_enemy(v2(32,64))
 enemy_manager:add_enemy(v2(64,32))
 enemy_manager:add_enemy(v2(64,96))
 enemy_manager:add_enemy(v2(96,64))
end

function _draw()
 frame+=1

 cls()
 if not is_screen_dark then
 end

 tick_crs(draw_crs)
 foreach(actors, function(a) a:draw() end)
 enemy_manager:draw()
 player:draw()
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)

 player:update()
 enemy_manager:update()
 foreach(actors, function(a) a:update() end)
end
