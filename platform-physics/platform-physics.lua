--#include oo
--#include v2
--#include bbox
--#include config
--#include constants
--#include hitbox
--#include menu
--#include helpers
--#include room
--#include player

menu=cls_menu.init()
local player=cls_player:init()
room=cls_room:init()
frame=0
dt=0
local lasttime=time()

function _init()
 menu.visible=false

local e=cls_menu_numberentry.init(
 "gravity",
 function(v) gravity=v end,
 0.12,0,0.3,0.05)
add(menu.entries,e)
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 if ((btnp(3) and btn(2)) or (btn(3) and btnp(2)))  menu.visible=not menu.visible

 if (menu.visible) menu:update()
 player:update()
end

function _draw()
 frame+=1
 cls()
 room:draw()
 player:draw()
 if (menu.visible) menu:draw()
end
