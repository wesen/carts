--#include oo
--#include menu
--#include helpers

local menu=cls_menu.init()

local radius=1
local spd=2
local pos_x=1
local draw_circle=true

function _init()
  menu:add("hide circle",
  function(self)
    if draw_circle then
     draw_circle=false
     self.text="draw circle"
    else
     draw_circle=true
     self.text="hide circle"
   end
  end)

  local e=cls_menu_numberentry.init(
   "radius",
   function(v) radius=v end,
   1,1,10)
  add(menu.entries,e)
  e=cls_menu_numberentry.init(
   "spd",
   function(v) spd=v end,
   10,1,20)
  add(menu.entries,e)
end

function _update()
  if (menu.visible) menu:update()
  pos_x=(pos_x+spd)%128
end

function _draw()
 cls()
 if (draw_circle) circfill(pos_x,64,radius,8)
 if (menu.visible) menu:draw()
end
