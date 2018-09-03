pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function class (init)
  local c = {}
  c.__index = c
  c._ctr=init
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    return self
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,{__index=parent})
end

cls_menu=class(function(self)
  self.entries={}
  self.current_entry=1
  self.visible=true
end)

function cls_menu:draw()
  local h=8 -- border
  for entry in all(self.entries) do
    h+=entry:size()
  end

  local w=64
  local left=64-w/2
  local top=64-h/2
  palt(0,false)
  rectfill(left,top,64+w/2,64+h/2,5)
  palt()
  rect(left,top,64+w/2,64+h/2,7)
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

cls_menu_numberentry=class(function(self,text,callback,value,min,max,inc)
  self.text=text
  self.callback=callback
  self.value=value
  self.min=min or 0
  self.max=max or 10
  self.inc=inc or 1
  self.state=0 -- 0=close, 1=open
  if (self.callback!=nil) self.callback(self.value,self)
end)

function cls_menu_numberentry:size()
  return self.state==0 and 8 or 18
end

function cls_menu_numberentry:activate()
  if self.state==0 then
    self.state=1
  else
    if (self.callback!=nil) self.callback(self.value,self)
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
    local pct=(self.value-self.min)/(self.max-self.min)
    print(tostr(self.value),right+5,y+off-2,7)
    spr(1,left-2+pct*w,y+off-2)
  end
end

function cls_menu_numberentry:update()
  if (btnp(0)) self.value=max(self.min,self.value-self.inc)
  if (btnp(1)) self.value=min(self.max,self.value+self.inc)
  if (self.callback!=nil) self.callback(self.value)
end

function tidx_inc(idx,n)
  return (idx%n)+1
end

function tidx_dec(idx,n)
  return (idx-2)%n+1
end


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

__gfx__
00000000666760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000006000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
