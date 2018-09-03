--#include oo
--#include menu
--#include helpers

-- menu class
cls_menu=class(function(self)
 self.entries={}
 self.current_entry=1
end)

function cls_menu:add(text,cb)
  add(self.entries,cls_menuentry.init(text,cb))
end

function cls_menu:update()
  local e=self.current_entry
  local n=#self.entries
  self.current_entry=btnp(3) and tidx_inc(e,n) or (btnp(2) and tidx_dec(e,n)) or e

  if (btnp(5)) self.entries[self.current_entry]:activate()
  self.entries[self.current_entry]:update()
end

function cls_menu:draw()
  local h=8
  for entry in all(self.entries) do
    h+=entry:size()
  end

  local w=64
  local left=64-w/2
  local right=64+w/2
  local top=64-h/2
  local bottom=64+h/2
  rectfill(left,top,right,bottom,5)
  rect(left,top,right,bottom,7)
  top+=6
  local y=top

  for i,entry in pairs(self.entries) do
    local off=0
    if i==self.current_entry then
     off+=1
     spr(2,left+3,y-2)
    end
    entry:draw(left+10+off,y)
    y+=entry:size()
  end
end

-- menu entry class
cls_menuentry=class(function(self,text,callback)
  self.text=text
  self.callback=callback
end)

function cls_menuentry:draw(x,y)
  print(self.text,x,y,7)
end

function cls_menuentry:size()
  return 8
end

function cls_menuentry:activate()
  if (self.callback!=nil) self.callback(self)
end

function cls_menuentry:update()
end

-- number entry
cls_menu_numberentry=class(function(self,text,callback)
  self.text=text
  self.callback=callback
  self.state=0 -- 0=close, 1=open
end)

function cls_menu_numberentry:size()
  return self.state==0 and 8 or 18
end

function cls_menu_numberentry:activate()
  if self.state==0 then
    self.state=1
  else
    self.state=0
  end
end

function cls_menu_numberentry:draw(x,y)
  if self.state==0 then
    print(self.text,x,y,7)
  else
    print(self.text,x,y,7)

    local off=10
    local w=24
    local left=x
    local right=x+w
    line(left,y+off,right,y+off,13)
    line(left,y+off,left,y+off+1)
    line(right,y+off,right,y+off+1)
    line(left+1,y+off+2,right-1,y+off+2,6)
    local pct=0
    print(0,right+5,y+off-2,7)
    spr(1,left-2+pct*w,y+off-2)
  end
end

function cls_menu_numberentry:update()
end

-- main code
local radius=1
local spd=2
local pos_x=1
local draw_circle=true

local menu=cls_menu.init()
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
local e=cls_menu_numberentry.init("radius", function() end)
add(menu.entries,e)
local e=cls_menu_numberentry.init("spd", function() end)
add(menu.entries,e)

function _update()
  menu:update()
  pos_x=(pos_x+spd)%128
end

function _draw()
 cls()
 if (draw_circle) circfill(pos_x,64,radius,8)
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