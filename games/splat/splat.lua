--#include helpers
--#include oo
--#include v2
--#include bbox
--#include hitbox
--#include globals

--#include fade
--#include coroutines
--#include clock
local clock=cls_clock.init(v2(100,100))

--#include clock-control
local clock_control=cls_clock_control.init()

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
 clock:draw()
end

function _update60()
 clock_control:update()
 dt=clock_control:get_dt()
 lasttime=time()
 tick_crs(crs)

 player:update()
 enemy_manager:update()
 foreach(actors, function(a) a:update() end)
 clock:update()
end
