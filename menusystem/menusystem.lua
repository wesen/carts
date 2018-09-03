--#include oo
--#include menu
--#include helpers

cls_menu=class(function(self)
 self.entries={}
end)
function cls_menu:update() end
function cls_menu:draw()
  local h=8
  for entry in all(self.entries) do h+=8 end
  local w=64
  local left=64-w/2
  local right=64+w/2
  local top=64-h/2
  local bottom=64+h/2
  rectfill(left,top,right,bottom,5)
  rect(left,top,right,bottom,7)
  top+=6
  local y=top
  for entry in all(self.entries) do
    print(entry,left+10,y)
    y+=8
  end
end

function cls_menu:add(text)
  add(self.entries,text)
end

local menu=cls_menu.init()
menu:add("entry 1")
menu:add("entry 2")
menu:add("entry 3")

function _update()
  menu:update()
end

function _draw()
  cls()
  menu:draw()
end

--[[
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

]]
