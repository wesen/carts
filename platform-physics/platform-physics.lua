--#include oo
--#include v2
--#include bbox
--#include constants
--#include hitbox
--#include menu
--#include helpers
--#include room
--#include player

local menu=cls_menu.init()
local player=cls_player:init()
room=cls_room:init()
frame=0
dt=0
local lasttime=time()

function _init()
 menu.visible=false
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 player:update()
 if (menu.visible) menu:update()
end

function _draw()
 frame+=1
 cls()
 room:draw()
 player:draw()
 if (menu.visible) menu:draw()
end
