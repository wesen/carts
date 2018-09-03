--#include oo
--#include v2
--#include menu
--#include helpers
--#include player

local menu=cls_menu.init()
local player=cls_player:init()
frame=0

function _init()
 menu.visible=false
end

function _update()
 player:update()
 if (menu.visible) menu:update()
end

function _draw()
 frame+=1
 cls()
 player:draw()
 if (menu.visible) menu:draw()
end
