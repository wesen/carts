function mrnd(n)
 return rnd(n*2)-n
end

function gen_bg()
 gen_sprite(0,0)
 gen_sprite(32,0)
 gen_sprite(64,0)
 gen_sprite(96,0)
end

function draw_gen_bg(n)
 srand(n)
 for i=0,10 do
  for j=0,3 do
  draw_sprite(j,
    flr(rnd(256)),
    flr(rnd(48))-16,
    rnd(32)+16,rnd(32)+16,
    maybe(),maybe())
  end
 end
 srand(time())
end

function draw_sprite(i,x,y,w,h,fliph,flipv)
 sspr(i*32,64,32,32,x,y,w,h,fliph,flipv)
end

function gen_sprite(dx,dy)
 cls()
 local m=9
 local mw=16
 local mh=16
 local sx=(m+1)*8
 for i=0,0 do
  local x,y=rnd(mw),rnd(mh)
  local w=flr(min(mw-x,rnd(mw/6)))
  x,y=flr(x),flr(y)
  local h=min(mh-y,rnd(mh/6))
  h=w
  local c=sget(
     sx+x/(mw/8),
     y/(mh/8))
  rectfill(x,y,x+w,y+h,c)
 end
 
 for i=0,400 do
  local x,y=rnd(mw),rnd(mh)
  local w=flr(max(1,rnd(5)))
  local h=w
  local c=sget(
     sx+x/(mw/8),
     y/(mh/8))
  x,y=flr(x),flr(y)
  if c!=0 or true then
   x+=rnd(10)
   y+=rnd(10)
   if rnd(1)>0.2 then
    rect(x,y,x+w,y+h,c)
   else
    rectfill(x,y,x+w,y+h,c)
   end
  end
 end
 for i=1,32 do
  memcpy(0x1000+dy*64+dx/2+i*64,
         0x6000+i*64,
         16)
 end
end
