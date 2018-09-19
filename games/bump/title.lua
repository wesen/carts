title_w=5*8
title_h=2*8
title_dx=25
title_dy=10
title_ssx=11*8
title_ssy=12*8

function draw_title(s)
 cls()
 local f=flr(frame/6)%3

 if f==1 then
  draw_title_frame1()
 else
  pal(7,12)
  -- srand(f)
  draw_title_frame2(-1)
  draw_random_line(7)

  if f==2 then
   pal(7,7)
   fillp(0x5a5a)
   rectfill(title_dx-3,title_dy+8,title_dx+2,title_dy+12,7)
   fillp(0xa0a0)
   rectfill(title_dx+60,title_dy+30,title_dx+66,title_dy+34,12)
   rectfill(title_dx+62,title_dy+28,title_dx+68,title_dy+32,7)
  end

  pal(7,8)
  -- srand(f)
  draw_title_frame2(1)
  srand(f+1)
  draw_random_line(7)

  pal()
  -- srand(f)
  draw_title_frame2(0)
  -- srand(f+2)
  draw_random_line(0)
 end

 palt(0,true)

 fillp()
 glitch_str(s)
end

function glitch_str(s)
 if (frame%10)<3 then
  aberration_str("- pixelgore 2018 -",title_dy+39)
  aberration_str("- press space to start -",title_dy+48)
  if (s!=nil) aberration_str(s,title_dy+96)
  for i=0,1 do
   draw_random_line(0,title_dx+15,title_dy+33,1)
   draw_random_line(7,title_dx+15,title_dy+33,1)
   draw_random_line(12,title_dx+15,title_dy+33,1)
   draw_random_line(8,title_dx+15,title_dy+33,1)
  end
 elseif (frame%10<8) then
  center_print("- pixelgore 2018 -",title_dy+39)
  center_print("- press space to start -",title_dy+48)
  if (s!=nil) center_print(s,title_dy+96)
 end
end

function center_str_x(s)
 return 64-(#s*4)/2
end

function center_print(s,y)
 print(s,center_str_x(s),y,7)
end

function aberration_str(s,y)
 local x=center_str_x(s)
 print(s,x+mrnd(2),y+mrnd(2)+1,12)
 print(s,x+mrnd(2),y+mrnd(2),8)
 print(s,x,y,7)
end

function draw_title_frame1()
 pal(7,12)
 sspr(title_ssx,title_ssy,title_w,title_h,title_dx-1,title_dy,title_w*2,2*title_h)
 pal(7,8)
 sspr(title_ssx,title_ssy,title_w,title_h,title_dx+1,title_dy,title_w*2,2*title_h)
 pal()
 sspr(title_ssx,title_ssy,title_w,title_h,title_dx,title_dy,title_w*2,2*title_h)
end

function draw_random_line(col,offx,offy,cnt)
 if (offx==nil) offx=title_dx
 if (offy==nil) offy=title_dy+10
 if (cnt==nil) cnt=5

 for i=0,cnt do
  palt(col,false)
  local x=rnd(title_w+10)+offx
  local y=rnd(title_h+5)+offy
  local w=rnd(10)
  line(x,y,x+w,y,col)
  palt()
 end
end

function draw_title_frame2(addx)
 local sy=0
 while sy<title_h do
  local sx=0
  local dh=min(title_h-sy,flr(rnd(3)+3))

  local offy=mrnd(1)
  while sx<title_w do
   local dw=min(title_w-sx,flr(rnd(5)+5))
   local offx=mrnd(1)
   offy+=mrnd(.5)
   sspr(title_ssx+sx,title_ssy+sy,dw,dh,title_dx+sx*2+offx+addx,title_dy+sy*2+offy,dw*2,dh*2)
   sx+=dw
  end

  sy+=dh
 end
end
