pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
p1={x=0,y=10}
p2={x=40,y=10}
p3={x=15,y=5}
p4={x=70,y=45}
l1={a=p1,b=p2}
l2={a=p3,b=p4}

p5={x=30,y=15}
p6={x=70,y=40}

box={a=p5,b=p6}

function draw_box(b,col)
 rect(b.a.x,b.a.y,b.b.x,b.b.y,col)
end

function draw_line(l,col)
 line(l.a.x,l.a.y,l.b.x,l.b.y,col)
end

function _init()
 poke(0x5f2d, 1) 
end

function _update()
 l1.a.x=stat(32)
 l1.a.y=stat(33)
end

function _draw()
 for i=0,500 do
  linebox(l1,box)
 end
 
 cls()
 print("cpu "..tostr(stat(1)),64,64,1)
 draw_line(l1,7)
 draw_line(l2,8)
 draw_box(box,9)

 local p,intersects=lineline(l1,l2)
 local circ_col=intersects and 7 or 8
 if p!=nil then
  circ(p.x,p.y,3,circ_col)
 end
 local ps=linebox(l1,box)
 for p in all(ps) do
  circ(p.x,p.y,3,12)
 end
end

function linebox(l,b)
 local res={}
 local p2={x=b.a.x,y=b.b.y}
 local p3={x=b.b.x,y=b.a.y}
 local l1={
     a=b.a,
     b=p2}
 local l2={
     a=b.a,
     b=p3}
 local l3={
     a=b.b,
     b=p2}
 local l4={
     a=b.b,
     b=p3}
 local p,is=lineline(l,l1)
 if (is) add(res,p)
 p,is=lineline(l,l2)
 if (is) add(res,p)
 p,is=lineline(l,l3)
 if (is) add(res,p)
 p,is=lineline(l,l4)
 if (is) add(res,p)
 
 return res
end

function lineline(l1,l2)
 local dx43=l2.b.x-l2.a.x
 local dy13=l1.a.y-l2.a.y
 local dy43=l2.b.y-l2.a.y
 local dx13=l1.a.x-l2.a.x
 local dx21=l1.b.x-l1.a.x
 local dy21=l1.b.y-l1.a.y
 local div=dy43*dx21-dx43*dy21
 if div==0 then
  -- test code
  return nil,false
 end
 
 local ua=dx43*dy13-dy43*dx13
 ua/=div
 local ub=dx21*dy13-dy21*dx13
 ub/=div
 
 local x=l1.a.x+ua*dx21
 local y=l1.a.y+ua*dy21
 
 local is01=function(x) 
  return x>=0 and x<=1
 end
 
 local intersects=is01(ua) and is01(ub)
 
 return {x=x,y=y},intersects
end
