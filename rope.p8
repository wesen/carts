pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
 poke(0x5f2d,1)
end

obj={
 x=63,y=28,
 sx=0,sy=2
}

maxl=10
maxfall=3
gravity=0.12

px=30
py=28
x=0
y=0

function _update()
-- x=stat(32)
-- y=stat(33)
 obj.sy=appr(obj.sy,maxfall,gravity)
 local prevx=obj.x
 local prevy=obj.y
 obj.y+=obj.sy
 obj.x+=obj.sx
 
 local v={x=obj.x-px,y=obj.y-py}
 local l=sqrt(v.x^2+v.y^2)
 if l>maxl then
  v.x=v.x*maxl/l
  v.y=v.y*maxl/l
  obj.x=px+v.x
  obj.y=py+v.y
  obj.sx=obj.x-prevx
  obj.sy=obj.y-prevy
 end
end

function _draw()
 cls()
-- line(px,py,x,y,7)
-- local a=atan2(x-px,y-py)
-- print(tostr(x)..","..tostr(y),64,80,7)
-- print(tostr(a),64,64,7)
 line(obj.x,obj.y,px,py,7) 
end
-->8
function appr(val,target,amount)
 return (val>target and max(val-amount,target)) or min(val+amount,target)
end

