p1=v2(10,10)
p2=v2(75,50)
l1=bbox(p1,p2)

p3=v2(5,15)
p4=v2(55,75)
b=bbox(p3,p4)

function draw_box(b,col)
 rect(b.aa.x,b.aa.y,b.bb.x,b.bb.y,col)
end

function draw_line(l,col)
 line(l.aa.x,l.aa.y,l.bb.x,l.bb.y,col)
end

function _init()
 poke(0x5f2d,1)
end

function _update()
 if band(stat(34),1)!=0 then
  l1.bb.x=stat(32)
  l1.bb.y=stat(33)
 elseif band(stat(34),2)!=0 then
  l1.aa.x=stat(32)
  l1.aa.y=stat(33)
 end
end

function _draw()
 cls()
 print("cpu "..tostr(stat(1)),64,64,1)
 draw_box(b,7)
 draw_line(l1,8)

  for p in all(isect(l1,b)) do
   circ(p.x,p.y,3,12)
  end
 end