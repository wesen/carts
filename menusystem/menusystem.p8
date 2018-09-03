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
end)

function cls_menu:draw()
  local h=#self.entries*8+8
  local w=48
  local left=64-w/2
  local top=64-h/2
  rect(left,top,64+w/2,64+h/2,7)
  top+=6-8
  for i,entry in pairs(self.entries) do
    local off=0
    if (i==self.current_entry) off+=1
    entry:draw(left+10+off,top+i*8)
  end
  spr(2,left+3,top-2+self.current_entry*8)
end

function cls_menu:add(text,cb)
  add(self.entries,cls_menuentry.init(text,cb))
end

function cls_menu:update()
  local e=self.current_entry
  local n=#self.entries
  self.current_entry=btnp(3) and tidx_inc(e,n) or (btnp(2) and tidx_dec(e,n)) or e
end

cls_menuentry=class(function(self,text,callback)
  self.text=text
  self.callback=callback
end)

function cls_menuentry:draw(x,y)
  print(self.text,x,y,7)
end

function tidx_inc(idx,n)
  return (idx%n)+1
end

function tidx_dec(idx,n)
  return (idx-2)%n+1
end


local menu=cls_menu.init()

function _init()
  menu:add("test",function() printh("test callback") end)
  menu:add("test2",function() printh("test2 callback") end)
  menu:add("test3",function() printh("test3 callback") end)

end

function _update()
  menu:update()
end

function _draw()
 cls()
 menu:draw()
end

__gfx__
00000000666760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000006000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
