function mka(x,y,dx,dy,dw,dh,fmax,spd)
 local e=mke(-1,x,y)
 e.lp=false
 e.size=dw
 e.draw=function(e,x,y)
  f=flr(e.t/spd)
  if f>=fmax then 
   kill(e) 
  else
   sspr(dx+dw*f,dy,dw,dh,x,y)
  end
 end
	return e
end

