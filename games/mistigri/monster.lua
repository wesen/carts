function mkm(mt,x,y)
 local e=mke(64+mt,x,y) 
 e.raymod=2
 add(monsters,e)
 e.phys=true
 e.obj=true
 e.bad=true
 e.dmg=0
 e.res=3
 e.mt=mt
 e.spd=0.5 
 e.hit=hit
 e.shoot_cd=80
 
 e.upd=upd_mon
 e.draw=function(e,x,y)
  if e.stun and not e.stunshk then
		 sspr(24+mod(2,4)*8,8,8,4,x,y-4)
  end
 end 
 
 e.xpl=function(from)
  sfx(56)
  shk=4
		local b=mkb(e.mt,e)
  xpl(b)
  kill(e)
  return b
 end  
 init_mon(e)
end

function init_mon(e)
 e.bhv=crawl
 e.wfrmax=2
 e.shoot=shoot
 e.bncx=function(e)
  e.flp=-e.flp
 end  
 
 -- birds
 if e.mt==1 then  
  e.wfrmax=4
  e.bhv=nil
		setfly(e,0.75)
 end 
 
 -- ogre
 if e.mt==2 then
  e.test_shoot=function(h)
   return abs(h.y-e.y)<8 and face(e,h)
  end
 end 
  
 -- boomerangs
 if e.mt==3 then
  e.test_shoot=function(h)
   return dst(h,e)<48 and face(e,h) and not e.rmpo
  end
 end
 
 -- heavy
 if e.mt==4 then
  e.turn=1
  e.spd=1
  e.wfrmax=1
 end
 
 -- ghosts
 if e.mt==5 then
  e.bhv=haunt
  e.hit=nil
  e.wfrmax=3
  e.phys=false
  e.spd=0.25
  e.bad=false  
  function f()
   e.bad=true
  end
  function l()
   e.vis=e.t%2==0
  end 
  dl(80,f,l)  
 end 
 
 -- wheel
 if e.mt==6 then
  e.wfrmax=3
  e.test_shoot=function(h)
   return abs(h.x-e.x)<4 or abs(h.y-e.y)<4
  end  
  e.shoot=dash
 end 
 
 -- vampire
 if e.mt==7 then 
  e.res=6
		setfly(e,0.5)
 end  
end

function upd_mon(e)
 -- heal
 if e.dmg>=e.res then
  e.stuncd-=1
  if e.stuncd <= 0 then
   if e.stun then
    e.vy-=2
    init_mon(e)
    gomad(e) 
   end
   e.dmg=0
  end 
 end
 
 -- stun
 e.stun=e.dmg>=e.res
 if e.stun then
  e.we=0.25
  e.stunshk = e.stuncd<20 and t%2==0
  return
 end


 -- bhv
 if e.bhv then 
  e.bhv(e)
 end
 
 -- heavy
 if e.mt==4 then
  e.turn=e.flp
 end
 
end

function gomad(e)
 if e.mad then return end
 e.mad=true
 e.rmp=2  
 --e.spd+=0.5
end

function mon_jmp(e)
 lim=e.mad and 6 or 32
 if e.t<lim then
  e.flp =(flr(e.t/8)%2)*2-1
 elseif e.we==0 then
  e.fr=80+e.mt
  e.vy=-3.6
  e.we=0.25
  e.bncy=function(e)
   still(e)
   e.bhv=crawl
  end
 end
end
