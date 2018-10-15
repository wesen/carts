dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,13}

function darken(p,_pal)
 for j=1,15 do
  local kmax=(p+(j*1.46))/22
  local col=j
  for k=1,kmax do
   if (col==0) break
   col=dpal[col]
  end
  if (col==14) col=13
  if (col==2) col=5
  if (col==8) col=5
  pal(j,col,_pal)
 end
end

function palbg(col)
 for i=1,16 do
  pal(i,col)
 end
end

function bspr(s,x,y,flipx,flipy,col)
 palbg(col)
 spr(s,x-1,y,1,1,flipx,flipy)
 spr(s,x+1,y,1,1,flipx,flipy)
 spr(s,x,y-1,1,1,flipx,flipy)
 spr(s,x,y+1,1,1,flipx,flipy)
 pal()
 spr(s,x,y,1,1,flipx,flipy)
end

function bstr(s,x,y,c1,c2)
	for i=0,2 do
	 for j=0,2 do
	  if not(i==1 and j==1) then
	   print(s,x+i,y+j,c1)
	  end
	 end
	end
	print(s,x+1,y+1,c2)
end

function draw_rounded_rect1(x,y,w,col_bg,col_border)
 col_border=col_border or col_bg
 line(x,y-1,x+w-1,y-1,col_border)
 line(x,y+w,x+w-1,y+w,col_border)
 line(x-1,y,x-1,y+w-1,col_border)
 line(x+w,y,x+w,y+w-1,col_border)
 rectfill(x,y,x+w-1,y+w-1,col_bg)
end

function draw_rounded_rect2(x,y,w,col_bg,col_border1,col_border2)
 col_border1=col_border1 or col_bg
 col_border2=col_border2 or col_border1

 line(x,y-2,x+w-1,y-2,col_border2)
 line(x,y+w+1,x+w-1,y+w+1,col_border2)
 line(x-2,y,x-2,y+w-1,col_border2)
 line(x+w+1,y,x+w+1,y+w-1,col_border2)
 line(x,y-1,x+w-1,y-1,col_border1)
 line(x,y+w,x+w-1,y+w,col_border1)
 line(x-1,y,x-1,y+w-1,col_border1)
 line(x+w,y,x+w,y+w-1,col_border1)
 pset(x-1,y-1,col_border2)
 pset(x+w,y-1,col_border2)
 pset(x-1,y+w,col_border2)
 pset(x+w,y+w,col_border2)
 rectfill(x,y,x+w-1,y+w-1,col_bg)
end
