function mke(fr,x,y)
 fr=fr and fr or -1
 x=x and x or 0
 y=y and y or 0
 
 e={
  fr=fr,x=x,y=y,t=0,size=8,
  frict=1.0,
  flp=1, lp=true, vis=true,
  raymod=0,ofy=0,dp=1,
  bncx=function(e) e.vx=0 end,
  bncy=function(e) e.vy=0 end,
  van=kill,
 }
 still(e)
 add(ents,e)
 return e
end

function upe(e)
 e.t+=1
 e.ox=e.x
 e.oy=e.y
 
 -- counters
 for v,n in pairs(e) do
  if sub(v,1,1)=="c" then
   n-=1
   if n<=0 then
    e[v]=nil
   else
    e[v]=n
   end
  end
 end

 if e.upd then e.upd(e) end
 if e.obj or e.lift then objs+=1 end
 if e.turn and t%2==0 and not e.stun then
  e.rot=e.rot or 0
  e.rot=(e.rot+e.turn)%4 
 end
 e.vy+=e.we
 e.vx*=e.frict
 e.vy*=e.frict

 --and not col(e)

 local c=e.mad and 2 or 1
 local vvx=e.vx*c
 if e.bhv!=fly then c=1 end
 local vvy=e.vy*c

 if e.bvx then
  vvx+=e.bvx
  vvy+=e.bvy
  e.bvx*=0.85
  e.bvy*=0.85
 end
 
 if e.cfocus then
  vvx=0
  vvy=0
 end

	if e.phys  then
	
	 -- horizontal
	 e.x+=vvx
	 sx=sgn(vvx)	 
	 if col(e)==2 then	  
	  while col(e)==2 do
	   e.x-=sx	  
	  end
	  e.vx*=-1	
	  e.bncx(e) 
	 end 
	 
	 -- vertical
	 pcol=col(e)
	 e.y+=vvy
	 sy=sgn(vvy)
	 function hcol(e)
	  local n=col(e)
	  if n==1 and e.cgh then 
	   n=0 
	  end
	  return n==2 or (n==1 and sy>0 and pcol==0)
	 end	 
	 if hcol(e)  then	  
	  while hcol(e) do
	   e.y-=sy
	  end
	  majground(e)
			e.vy*=-1
			e.bncy(e) 
	 end
	 
	 -- ground test
  majground(e)
	else
	 e.x+=vvx
	 e.y+=vvy
	end
	
	-- tween
 if e.twc then
  tx=e.twt and e.twt.x or e.tx
  ty=e.twt and e.twt.y or e.ty
  e.twc=min(e.twc+e.spc,1)
  c=0.5-cos(e.twc*0.5)*0.5
  e.x=e.sx+(tx-e.sx)*c
  e.y=e.sy+(ty-e.sy)*c
  if e.twj then
   e.y+=sin(c*0.5)*e.twj
  end	
  if e.twc==1 then
   e.twc=nil  
   if e.twnxt then e.twnxt() end
  end
 end
 -- life
 if e.life then
  e.life-=1
  if e.blink and e.life < e.blink then
   e.vis=t%4<2
  end
  if e.life<=0 then
   e.van(e)
  end
 end
 
 -- bad
 if e.bad and not e.stun then
  h=herocol(e)
  if h and not h.cinv then
   if e.shot then kill(e) end
   if h.special==1 then
    if e.xpl then 
     e.xpl()
    end
   else
    die(h)   
   end
  end
 end 

 
 -- killmon
 if e.killmon then
  for m in all(monsters) do
   if ecol(m,e) then
    m.xpl()
   end
  end
 end
 
	-- mod
	if e.lp then
	 e.x=mdx(e.x)
	 e.y=mdy(e.y)
	else 
	 if out(e) and not e.ores then	  
	  kill(e)
	 end
	end
end

