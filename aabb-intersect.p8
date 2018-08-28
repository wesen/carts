pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
p1={x=10,y=10}
p2={x=75,y=50}
l1={a=p1,b=p2}

p3={x=5,y=15}
p4={x=55,y=75}
b={aa=p3,bb=p4}

function draw_box(b,col)
 rect(b.aa.x,b.aa.y,b.bb.x,b.bb.y,col)
end

function draw_line(l,col)
 line(l.a.x,l.a.y,l.b.x,l.b.y,col)
end

function isect(l,b)
 local res={}
 
 local dx=l.b.x-l.a.x
 local dy=l.b.y-l.a.y

 local u=0  
 if dx!=0 then
  u=(b.aa.x-l.a.x)
  if u<=dx and u>=0 then
   local u1=u/dx
   local y1=l.a.y+u1*dy
   if y1>=b.aa.y and y1<=b.bb.y then
    add(res,{x=l.a.x+u,y=y1})
   end
  end
 

  u=(b.bb.x-l.a.x)
  if u<=dx and u>=0 then
   local u1=u/dx
   local y1=l.a.y+u1*dy
   if y1>=b.aa.y and y1<=b.bb.y then
    add(res,{x=l.a.x+u,y=y1})
   end
  end
 end
 if dy!=0 then
  u=(b.aa.y-l.a.y)
  if u<=dy and u>=0 then
   local u1=u/dy
   local x1=l.a.x+u1*dx
   if x1>=b.aa.x and x1<=b.bb.x then
    add(res,{x=x1,y=l.a.y+u})
   end
  end
  u=(b.bb.y-l.a.y)
  if u<=dy and u>=0 then
   local u1=u/dy
   local x1=l.a.x+u1*dx
   if x1>=b.aa.x and x1<=b.bb.x then
    add(res,{x=x1,y=l.a.y+u})
   end
  end
 end
 
 return res
end

function _init()
 poke(0x5f2d,1)
end

function _update()
 if band(stat(34),1)!=0 then
  l1.b.x=stat(32)
  l1.b.y=stat(33)
 elseif band(stat(34),2)!=0 then
  l1.a.x=stat(32)
  l1.a.y=stat(33)
 end
  
end

function _draw()
 for i=0,500 do
  isect(l1,b)
 end

 cls()
 print("cpu "..tostr(stat(1)),64,64,1)
 draw_box(b,7)
 draw_line(l1,8)
 
 
 for p in all(isect(l1,b)) do
  circ(p.x,p.y,3,12)
 end
end
