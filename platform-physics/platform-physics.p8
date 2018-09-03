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

-- vectors
local v2mt={}
v2mt.__index=v2mt

function v2(x,y)
 local t={x=x,y=y}
 return setmetatable(t,v2mt)
end

function v2mt.__add(a,b)
 return v2(a.x+b.x,a.y+b.y)
end

function v2mt.__sub(a,b)
 return v2(a.x-b.x,a.y-b.y)
end

function v2mt.__mul(a,b)
 if (type(a)=="number") return v2(b.x*a,b.y*a)
 if (type(b)=="number") return v2(a.x*b,a.y*b)
 return v2(a.x*b.x,a.y*b.y)
end

function v2mt.__div(a,b)
 if (type(a)=="number") return v2(b.x/a,b.y/a)
 if (type(b)=="number") return v2(a.x/b,a.y/b)
 return v2(a.x/b.x,a.y/b.y)
end

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:min(v)
 return v2(min(self.x,v.x),min(self.y,v.y))
end

function v2mt:max(v)
 return v2(max(self.x,v.x),max(self.y,v.y))
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:sqrmagnitude()
 return self.x^2+self.y^2
end

function v2mt:normalize()
 return self/self:magnitude()
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
end

function v2mt:flr()
 return v2(flr(self.x),flr(self.y))
end

function v2mt:clone()
 return v2(self.x,self.y)
end

dir_down=0
dir_right=1
dir_up=2
dir_left=3

vec_down=v2(0,1)
vec_up=v2(0,-1)
vec_right=v2(1,0)
vec_left=v2(-1,0)

function dir2vec(dir)
 local dirs={v2(0,1),v2(1,0),v2(0,-1),v2(-1,0)}
 return dirs[(dir+4)%4]
end

function angle2vec(angle)
 return v2(cos(angle),sin(angle))
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
 rectfill(left,top,64+w/2,64+h/2,5)
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

-- implement bounded acceleration
function appr(val,target,amount)
 return (val>target and max(val-amount,target)) or min(val+amount,target)
end

function sign(v)
 return v>0 and 1 or v<0 and -1 or 0
end

function rndsign()
 return rnd(1)>0.5 and 1 or -1
end

function round(x)
 return flr(x+0.5)
end

function maybe(p)
 if (p==nil) p=0.5
 return rnd(1)<p
end

function mrnd(x)
 return rnd(x*2)-x
end

cls_player=class(function(self)
 self.pos=v2(64,64)
 self.spd=v2(0,0)
 self.spr=1
 self.flip=v2(false,false)
end)

function cls_player:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

function cls_player:update()
 self.spr=1+flr(frame/4)%3
end


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

__gfx__
0000000000ddd0000000000000ddd00000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddfdf0000ddd0000ddfdf000ddfdf000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700ddf1f1f00ddfdf00ddf1f1f0ddf1f1f000d00d000d0000d0000000000088008808800080008880808088008080080088808080000000000000000000
000770000ff1f1f0ddf1f1f00ff1f1f00ff1f1f00005500000d00d000dd00dd00090909009090909000900909090009990909009009090000000000000000000
0007700000ffff000ff1f1f000ffff0000ffff000058d8000558d8000555500000f0f0f00f0f0f0f000f00f0f0f000fff0f0f00f00f0f0000000000000000000
007007000009900000ffff0000044000000999600500d0000000d0000008d8000070707007070707000700707070007070707007007070000000000000000000
000000000004400000044000006006000004460000000000000000000000d0000077007707700707000700777077007070707007007770000000000000000000
00000000000660000006060000000000000000000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
000000000ff0ff0000000000f000f000000000000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
0990009900f00f0000f00f000fff0000008080000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
0095959000ffff0000ffff000cfc00000888780000000000000000000000000000f0f0f00f000f0f000f00f0f0f000f0f0f0f00f00f0f0000000000000000000
0009990000fcfc00f0fcfc0066e6600008e888000000000000000000000000000090909009000909000900909090009090909009009090000000000000000000
0009e900f0ffffe0f0fffef00f6f00f0008e80000000000000000000000000000088008808000080000800808088008080080008008080000000000000000000
00000009f0099000f0044f000fff00f0000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099909f0ffff00f0fff0000fff00f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009444900fffff400ff6f60005f5ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000800088008408000008800000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008480008400080000000000008e8000008e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008888800d0000d00000000000888880008e8800000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00488480000000000000000000288280000882000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000
000444000880000800000000000222000000200000020000000e0000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d800d808000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d00d008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000770700000770000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
70000600007700667000007000000000000000000000000000060000007700007000000000000000000000000000000000000000000000000000000000000000
00770000006600000000006700000000000000000000000000000700006000006600000000000000000000000000000000000000000000000000000000000000
07766000000000000000000000000000000000000000000000707700000000000000700000000000000000000000000000000000000000000000000000000000
0677770000000000000000000000000000000000000000000777770007007000000060000000000007000000c00000000000000007000000c000000000000000
077776000000000700000000007770000000770000000070006676007700600000000000000c0000c60000000000007007000000c60000000000007000000000
0076600700700000000000700777600077006770070000600000660006700000070000000077c0000c00770000000000c6000c000c0077000000000000000000
0000000676607000070007607667770076000660000000000000060000000000060000000c766cc0000006c0000000000c00c7c0000006c00000000000000000
65d6d656c776cc7c000000000000000000000000000000000000000085d88585cc6dc55dd55cd6ccc776cc7cc7cc677c00000000000000000000000000000000
006dd5007c5c566c00000000000000000000000000000000000000008dd0dd8076060d5dd5d060677c5c566cc665c5c700000000000000000000000000000000
d55655600c0c0c06000000000000000000000000006665000066650008000600c6cc00055000cc6c0c0c0c0660c0c0c000000000000000000000000000000000
5005566d500c5c6d6d0000000000000000000000006b65000068650008000800c50506d00d60505c500c5c6dd6c5c00500000000000000000000000000000000
005d000d005d000c0d6666500000000008000800006b650000686500000000006cccd50dd05dccc6005d000cc000d50000000000000000000000000000000000
000560d5555560d5d5d00d0000000000080006000065650000656500000000007500556dd6550057d65500577500556d00000000000000000000000000000000
5600d0555660d055550dd000056666508dd0dd80006d6500006d6500000000007cc0056556500cc756500cc77cc0056500000000000000000000000000000000
050005dd05dd05ddddd00d0000aaaa0085d88585006665000066650000000000c70505500550507c0550507cc705055000000000000000000000000000000000
cc6cc6cccc0000cc888ee88888eee88800eeee000000e00000eeee000eeeeee00000e00000eeeee0000eee000000000000000000000000000000000000000000
c6cc6ccccc0000cc00822000008888220e0000e0000ee00000e000e000000e00000e0e0000e0000000ee00000000000000000000000000000000000000000000
000000006c00006c0000000000028200e000000e00e0e00000e000e00000e00000e00e0000e000000e0000000000000000000000000000000000000000000000
00000000c60000c60000000000000000e000000e0000e000000000e00eeeee000e000e0000eeee00e00000000000000000000000000000000000000000000000
00000000cc0000cc0000000000000000e000000e0000e00000eeeee0000000e0e0000e0000000ee0eeeeeee00000000000000000000000000000000000000000
000000006c00006c0000000000000000e000000e0000e00000e00000000000e00eeeeeee000000e0e000000e0000000000000000000000000000000000000000
cc6cc6ccc60000c600000000000000000e0000e00000e00000e00000000000e000000e0000000ee00e00000e0000000000000000000000000000000000000000
c6cc6ccccc0000cc000000000000000000eeee0000eeeee000eeeee00eeeee0000000e0000eeee0000eeeee00000000000000000000000000000000000000000
00000000000000000000000000000000000000888800000000000088880000000000050000000000000005000000000000000000000000000000000000000000
000000000000000000000000000000000000008888000000000000888800000000000d000000000000000d000000000000000000000000000000000000000000
00000005d000000000000006d0000000000000000000000000000000000000000000060000000000000006000000000000000000000000000000000000000000
0000005005000000000000600600000000000d6666d0000000000d6666d0000000006d500000000000006d500000000000000000000000000000000000000000
000005d50d000000000006d50d000000000000555500000000000055550000000000999000000000000099900000000000000000000000000000000000000000
0000099905000000000009990d000000000000799700000000000000000000000000797000000000000009000000000000000000000000000000000000000000
000007970d000000000000900d000000000007777770000000000000000000000007777700000000000000000000000000000000000000000000000000000000
0000777776000000000000000d000000000007944970000000000076670000000057777750000000000000000000000000000000000000000000000000000000
00007777760000000000000005000000000079151597000000000755557000000577777775000000000000000000000000000000000000000000000000000000
0007777776000000000000000d000000000074515147000000000650056000005677777776500000000000000000000000000000000000000000000000000000
0007777776000000000000000d000000000774151547700000000650056000007777777777600000000000000000000000000000000000000000000000000000
0077777776700000000000000d000000000774515147700000000650056000007777777777700000000000000000000000000000000000000000000000000000
00777777767000000000000005000000007774151547770000000650056000007777777777700000000000000000000000000000000000000000000000000000
0777777776770000000000000d000000007774515147770000000650056000007777777777700000000000000000000000000000000000000000000000000000
077777776d570000000000006d500000077779151597777000000d5005d000005777777777500000000000000000000000000000000000000000000000000000
77777776d555700000000006d5550000077774515147777000000650056000000556666655000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007707700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3
