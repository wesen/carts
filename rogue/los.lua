function los(o1,o2)
  local sx,sy=o1.x,o1.y
  local lx,ly=o2.x-sx,o2.y-sy
  local slope,inc=abs(ly/lx),1
  local px,py=sx*8+4,sy*8+4

  if abs(lx)>abs(ly) then
    cnt,dx,dy=lx*8,1,slope
  else
    cnt,dx,dy=ly*8,1/slope,1
  end
  cnt=abs(cnt)
  dx*=sign(lx)
  dy*=sign(ly)
  for i=0,cnt do
    local _x,_y=flr(px/8),flr(py/8)
    pset(px,py,4)
    px+=dx
    py+=dy
    if sx!=_x or sy!=_y then
      sx,sy=_x,_y
      local tile,mob=mget(sx,sy),get_mob(sx,sy)
      local flag=fget(tile)
      if mob!=false or band(flag,4)!=4 then
        rect(sx*8,sy*8,sx*8+8,sy*8+8,12)
      end
    end
  end

end
