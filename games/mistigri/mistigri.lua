-- mistigri
-- 2016 benjamin soule
start_lvl=0
alph="cdeimnstxy"
--alphabet="abcdefghijklmnopqrstuvwxyz"
xtra_base={2000,8000,20000}
words="extendmystic"
bounty={10,20,30,50,100,500,100,200}
nf=function() end

time_limit=512

--#include helpers
--#include init
--#include menu
--#include game
--#include hero
--#include entity

function upd_congrats()
 foreach(ents,upe)  
 if #ggpos==0 then
  if #flowers>0 and t%2==0 then
   f=flowers[1]
   del(flowers,f)
   kill(f)
   b=mkbonus(48+rand(8),f)
  end 
 elseif rand(16)==0 then
  p=steal(ggpos)
  e=mke(244,p.x,p.y)
  e.rmpo={8,8+rand(8)}
  sfx(54)
  add(flowers,e)
 end    
end

function impulse(e,an,spd)
 e.vx=cos(an)*spd
 e.vy=sin(an)*spd
end

function corn()
 sfx(57)
 flash_bg=1
 tt=5
 spawn_item(cornucopia)
 if cornucopia==55 then 
  cornucopia=nil
 end 
end

block_max=12

--#include boss

function burning(e)
 p=mka(e.x+rand(3)-1,e.y+rand(3)-1,24,12,4,4,4,2)
 p.rmp=e.rmp
end

function add_block()
 sfx(49)
 local e=mke(224,0,0)
 e.bad=true
 e.blk=0
 e.dp=2
 e.hit=function(ff,dmg)
  dmg = dmg or 1
  sfx(58)
  e.flh=7
  e.blk+=dmg
  e.fr=224+e.blk
  if e.blk>=4 then
   kill(e)
   sfx(53)
   for i=0,4 do
    p=mka(e.x,e.y,8+rand(2)*4,104+rand(2)*4,4,4,1,64)
    impulse(p,rnd(),2)
    p.phys=true
    p.we=0.1
    p.bncy=function(p)
     p.vx*=0.75 
     p.vy*=-0.6 
    end
   end
  end
 end  
 e.xpl=e.hit
 add(monsters,e) 
 e.flh=2
 tt=4
 e.vis=false
 add(blocks,e) 
 if #blocks == block_max then
  bnext()
 else
  --dl(8,add_block)
  dl(12,add_block)
 end
end

--#include monster

function gms()
 sum=0
 for m in all(monsters) do
  if not m.blk then sum+=1 end
 end
 for h in all(heroes) do if h.lift then sum+=1 end end
 return sum
end

function setfly(e,spd)
 e.spd=spd
 e.bhv=fly
 e.vx=e.flp*e.spd
 e.vy=-e.spd
 e.bncy=nf
end

function fly(e)
	advf(e)
	--e.fr=64+e.mt+(flr(t/4)%e.wfrmax)*16
 e.we=0
 e.vx=e.flp*e.spd

 if e.t>64+e.y and e.mt==7 then
  e.t=0
  e.cfocus=16
 end
 if e.cfocus==1 then
  h=hcl(e)
  sfx(52)  
  an=sgda(h,e)  
  smax=e.mad and 2 or 0
  for i=0,smax do
   ba=(i-smax/2)*0.1
   f=badshot(94,e)  
   impulse(f,an+ba,2)
   f.raymod=3
   f.upd=function(f)
    f.flh=t%4<2 and 7 or nil
   end
   if ba==0 then    
 		 e.bvx=-f.vx
  		e.bvy=-f.vy
   end   
  end 
 end
 
end

function badshot(fr,e)
 local f=mke(fr,e.x,e.y)  
 f.bad=true
 f.shot=true
 f.bncx=function(b)
  kill(b)
 end
 f.lp=false
 return f
end

function haunt(e)
 advf(e)
 h=hcl(e)
 
 local dx=mdx(h.x-e.x,60)
 local dy=mdy(h.y-e.y,56)
 local an=atan2(dx,dy) 
 spd=e.spd*(1+cos(t/40)*0.5)
 impulse(e,an,spd)
 e.spd+=0.001
 e.shot=true
 e.flp = sgn(mdx(h.x-e.x,64))
 if gms()==1 or lt<time_limit then 
  vanish(e)
 end
end

function face(e,h)
 return e.flp==sgn(h.x-e.x) or e.mad 
end

function advf(e)
 e.fr=64+e.mt+mod(4,e.wfrmax)*16
end

function crawl(e) 

 h=heroes[1]
 hdy=hmod(h.y-e.y,60)
 
 --if seek then log(hdy) end
 if e.ground then
  if e.fall then
   e.vy=0
   e.fall=false
   if e.mt==4 then
    h=hcl(e)
    if h then
     e.flp=sgn(h.x-e.x)
    end
    if not e.mad then
     e.flp=rand(2)*2-1
    end
   end
   
  end
  

  fall=e.mt==4 or (e.mad and hdy>2) 

  --uturn= (not seek or hdy<2) and e.mt!=4
  
  if col(e,e.flp*8,1)==0 and not fall then
   e.flp=-e.flp
  end
  e.vx = e.flp*e.spd
  advf(e)

  -- try jump
  if seek and hdy<-2 and rand(2)==0 then
   px=flr(e.x/8)
   py=flr(e.y/8) 
   ok=false
   for i=1,2 do
    fr=lget(px,(py-i)%15)
    if fget(fr,1) then
     ok=true
    end
   end
   if ok then
    e.bhv=mon_jmp
    e.t=0
    e.vx=0
    e.fr=64+e.mt
   end  
  end 
  
  -- try shoot
  scd=e.bad and e.shoot_cd or 8
  if e.t>scd and e.test_shoot and rand(4)==0 then
   h=hcl(e)
   if e.test_shoot(h) then
    e.t=0
    e.shoot(e,h)
   end
  end
  
 else
  -- fall
  e.vx=0
  e.vy=2
  e.fall=true
 end 
end

function shoot(e,h)
 e.trg=h
 e.flp=sgn(h.x-e.x)
 e.bhv=mon_fire 
 e.vx=0  
 e.fr=96+e.mt
end

function dash(e,h)
 sfx(63)

 local an=flr(sgda(h,e)*4+0.5)/4
 still(e) 
 e.cgh=36
 local f=function(sh)
  dl(24,function() init_mon(e) end)
  shk=8
  sfx(62)
  e.bhv=nil
  e.fr=74
  still(e)
  e.bncy=nf
 end 

 local acc=0.2
 local spd=0
 e.bhv=function()
  spd+=acc
  impulse(e,an,spd)
  if not e.cgh then   
   spd*=0.85
   acc=0
			if spd<0.1 then
			 init_mon(e)
			end
  end
 end
 e.bncx=f
 e.bncy=f 
end

function hcl(e) 
 best=nil
 bdist=999
 for h in all(heroes) do
  dd=dst(h,e)
  if dd<bdist and h.act then
   best=h
   bdist=dd
  end
 end
 if not best then
  return heroes[1]
 end
 return best
end

function mon_fire(e)
 if e.t==12 then 
  
  e.fr=112+e.mt
  local b=badshot(104,e)
  b.turn=1

  
  if e.mt==3 then
   e.rmpo={9,0}
   b.lp=false
   b.rmp=e.rmp
   b.fr=119  
   b.raymod=2
   an=sgda(e.trg,b)
   impulse(b,an,b.mad and 5 or 3)
   b.frict=0.95
   local spd=0
   b.upd=function()
    if b.t%4==0 then
     sfx(50)
    end
    if e.dead then
     b.frict=1.05
    elseif b.t>24 then
     spd+=0.15
     an=sgda(e,b)
     impulse(b,an,spd)
     if dst(e,b)<4 then
      sfx(49)
      kill(b)
      e.rmpo=nil     
     end
    end
   end
  else
   b.vx=e.flp*2
   b.phys=true  
   sfx(44)
  end
 end
 
 if e.t==20 then
  e.bhv=crawl
 end 
 
end

function hit(e,n,sd) 
 e.flh=7
 tt=2
 e.dmg+=n
 if e.dmg>=e.res then
  stun(e,sd)
 else
  sfx(36)
 end 
end

function stun(e,sd)
 sfx(37)
 e.stuncd=sd
 e.vx=0 
 e.fr=64+e.mt
 e.we=0.25
 e.bncy=function(e) e.vy=0 end
end

function drop(h)
 e=h.lift
 h.lift=nil
 add(monsters,e)
 add(ents,e)
 e.x=h.x+h.flp*8
 e.y=h.y	   
end

function die(h)
 kill(h)
 if h.lift then
  drop(h)
 end
 
 sfx(43)
 e=mke(40,h.x,h.y)
 e.size=7
 e.we=1
 e.phys=true
 e.vy=-5
 e.flp=h.flp
 e.bncy=function(e) 
  e.vy*=-0.75 
  if e.t>20 then 
   e.we=0
   e.vy=0
  end
 end
 e.life=40
 e.blink=12   
 if lives>0 then
  lives-=1
  life_lost=30
  e.ondeath=function()
   spawn_hero(h)
   h.cinv=64
  end
 else
  h.act=false
  act-=1 	
 end
 
 shk=6
 flash_bg=0
 tt=3 
 for i=0,15 do
  --e=mke(74,h.x,h.y)
  e=mka(h.x,h.y,40,12,4,4,4,2+rand(4))
  impulse(e,(i+rnd())/15,4)
  e.frict=0.75+rnd(0.15)
  e.blid=h.hid
  e.phys=true
  e.we=0.1
  e.size=0.5
  
  e.bncy=function(e) e.vy*=-0.75 end
 end
 
end

function shoot_ball(h)
 h.cdb=10/h.ball4
 sfx(34)
 
 for e in all(ents) do
  if e.blid==blid then
   kill(e)
  end
 end
 
 pw=h.ball3>blid+1 and 2 or 1

 --pw=h.ball3
 b=mke(4+pw,h.x,h.y)
 b.pow=pw
 b.raymod=-2
 b.vx=h.flp*(0.5+h.ball2/2)
 b.vy=-2.3
 b.we=0.25 
 b.phys=true
 b.size=3+pw
 b.life=h.ball1*60
 b.blid=blid
 blid=(blid+1)%(3+h.ball0)
 b.bncx=function(b) 
  sfx(32)
 end
 b.bncy=function(b)
  b.vy=max(b.vy,-2.5)
  sfx(32)
 end 
 
 b.upd=function(b)
  for e in all(ents) do
   if e.hit and ecol(e,b) then
    e.hit(e,b.pow,160*h.ball5)
    an=sgda(e,b)
    e.bvx=cos(an)*1
    e.bvy=sin(an)*1
    kill(b)
   end
  end
 end 
 b.ondeath=function(b)
  sfx(33)
  mke(32,b.x,b.y)
 end
 add(balls,b)
end


function fadeto(nxt,rev)
 fade_rev=rev
 fade_nxt=nxt
 fade_n=0
end

function mkb(mt,from)
 local e=mke(64+mt,from.x,from.y)
 e.mt=mt
 e.rmp=1
 e.obj=true
 e.phys=true
 e.proj=true
 e.vx=8
 e.lvb=lvb
 lvb+=1
 bnum+=1
 e.ondeath=function()bnum-=1 end
 e.bncx=function(e)
  sfx(41)
  if e.proj then
   xpl(e)
   sfx(56)
   shk=4  
  end
 end 
 
 local lim=32+rnd(48)
 e.bncy=function(e)
  sfx(41)
  if e.ground then
   e.t+=2
   if e.t>lim and not e.proj then
    b=mkbonus(48+e.lvb,e)
    kill(e)
   end
  end
 end  
 
 e.rot=0
 e.turn=1
 e.upd=function(e)  
  m=moncol(e)
  if e.t>40 then 
	 	xpl(e)
   e.vy=0
  elseif m and not e.cdt then
   e.vx*=-1
   e.cdt=4
   b=m.xpl(e)
   if b then
    b.vx=-e.vx
   end
  end
 end
 return e
end
 
function xpl(e)
 --

 if e.proj then
  add_score(heroes[1],bounty[e.mt+1],e.x,e.y)
  e.t=0
  e.proj=false
  e.lp=true
  e.vy=-8
  e.upd=nil
  e.frict=0.97
  e.we=0.25  
 end
end

function launch(h)
 sfx(39)
 e=mkb(h.lift.mt,h) 
 e.vx=h.flp*8
 h.lift=nil
end

function mkbonus(fr,p)
 sfx(48)
 e=mke(fr,p.x,p.y)
 e.obj=true
 e.van=vanish 
 e.dp=0
 e.vy=-2
 e.we=0.25
 e.phys=true 
 
 local let
 if fr==4 then
  let=rand(#alph)
 end 
 e.upd=function(e)
  local h=herocol(e)  
  if h then
   if let then
    sfx(42)
    add_let(let)
   elseif fget(fr,6) then
    nsfx=42
    add_score(h,50*(fr-47),e.x,e.y)
   else
    apply_effect(fr,h)
   end
   kill(e)
  end  
 end
 e.life=240
 e.blink=60
 
 if let then
  e.draw=function(e,x,y)
   for i=0,1 do
    print(glet(let),x+3-i,y+2-i,1+6*i)
    bt=e.t%40
    if bt<4 then
   	 spr(7+bt,x,y)
   	end
   end
  end
  e.hit=function(e)
  	sfx(45)
   let=(let+1)%#alph
   e.t=0
  end  
 end
 return e 
end

function nuke()
 for m in all(monsters) do
  m.xpl()
 end
end

function apply_effect(fr,h)
 -- rod
 if fr==56 then
  sfx(53)
  music(30)
  flash_bg=0
  tt=7
		nuke()
 end
 
 --- earrings
 if fr==57 then
  for i=0,1 do
   b=mke(47,0,0)
   b.killmon=true
   b.rmp=0
   b.upd=function(b)
    an=i/2+t/40
    b.x=h.x+cos(an)*16
    b.y=h.y+sin(an)*16
    burning(b)
   end
  end
  --h.powerballs=3
 end
 
 -- match
 if fr==58 then
  h.special=0
 end
 
 -- gong
 if fr==59 then
  sfx(40)
 	for m in all(monsters) do
 	 m.dmg=m.res
 	 stun(m,160)
 	 m.vy=-2
 	 shk=8
 	end
 end
 
 -- all potion
 if fr>=228 then
  sfx(29)
  s="ball"..(fr-228)
  h[s]=h[s]+1
 end
 
 -- key
 if fr==127 then
  jump_lvl=22
  leave()
  music(17)
 end

 -- bomb
 if fr==60 then
  sfx(44)
  shk=32
  for i=0,3 do
   e=mke(104,h.x,h.y)
   impulse(e,i/4+0.12,3)
		 e.phys=true
		 e.bncx=nf
		 e.bncy=nf
		 e.killmon=true
		 e.upd=burning
		 e.cgh=512
		 e.turn=1
		end
 end

 -- bell
 if fr==61 then
  for i=0,11 do
   local p=steal(ggpos)
   local bf=big_fruit
   dl(i*4,function() mkbonus(bf,p) end)
  end   
		big_fruit+=1
 end
 
 -- necklace
 if fr==62 then
 	music(31)
 	h.special=1 
 end
 
 -- cornucopia
 if fr==63 then
  sfx(57)
 	cornucopia=48 
 	corn()
 end
 
end


function add_let(n)
 for l in all(letters) do
  if not l.act and glet(n)==l.let then
   l.act=true
   break
  end
 end
 
 for i=0,1 do
  ok=true
  for k=1,6 do
   ok=ok and letters[i*6+k].act
  end
  if ok then   
   success=i
   
   dl(80,function() success=nil end)
   for k=1,6 do 
    letters[i*6+k].act=false
   end 
   if i==0 then
    extra_life()
   else
    jump_lvl=5
   end
   nuke()
   music(-1)
  end  
 end
end

function dl(t,f,l)
 e=mke(-1,0,0)
 e.life=t
 e.ondeath=f
 e.upd=l
end

function glet(n)
 return sub(alph,n+1,n+1)
end

function extra_life()
 lives+=1
 nsfx=10
 flash_bg=2
 tt=7 
end

function add_score(h,sc,x,y)
 h.score+=sc
 if #xtra>0 and h.score>=xtra[1] then
  del(xtra,xtra[1])
  extra_life()
 end
 
 e=mke(-1,x,y-4)
 e.vy=-0.25
 e.life=24
 e.dp=0
 local s=sc..""
 e.draw=function(e,x,y)
  for i=0,1 do
   cl=1
   if i==1 then
    cl=t%4<2 and 7 or 12
   end
   print(s,x+4-#s*2-i,y+2-i,cl)
  end
 end
 
end


function ecol(a,b)
 dx=a.x-b.x
 dy=a.y-b.y
 if a.lp and b.lp then
  dx=mdx(a.x-b.x,60)
  dy=mdy(a.y-b.y,54)
 end
 dx=abs(dx)+a.raymod+b.raymod
 dy=abs(dy)+a.raymod+b.raymod
 local l=(a.size+b.size)/2
 return dx<l and dy<l
end

function moncol(e)
 for m in all(monsters) do
  if ecol(m,e) and m.hit then
		 return m
  end
 end
 return nil
end

function herocol(e)
 for h in all(heroes) do
  if h.act and ecol(h,e) and not h.dead then
		 return h
  end
 end
 return nil
end

function tw(e,tx,ty,n,twj,nxt)
 e.sx=e.x
 e.sy=e.y
 e.tx=tx
 e.ty=ty
 e.twc=0
 e.twj=twj
 e.spc=1/n
 if n<0 then
  local dx=tx-e.x
  local dy=ty-e.y
  local dd=sqrt(dx*dx+dy*dy)
  if twj then dd+=twj*1.4 end
  e.spc=-n/dd
 end
 e.twnxt=nxt
end

function vanish(e)
 mke(23,e.x,e.y)
 kill(e)
end

function majground(e)
 e.ground=col(e,0,1)>0 and col(e,0,0)==0
end

function out(e)
 return e.x<-4 or e.y<-4 or e.x>132 or e.y>132
end

function kill(e)
 e.dead=true
 del(ents,e)
 del(balls,e)
 del(monsters,e)
 if e.ondeath then 
  e.ondeath(e) 
 end
end

function mdx(n,k)
 k=k or 0
 n+=k
 return (n%120)-k
end
function mdy(n,k)
 k=k or 0
 n+=k
 return (n%112)-k
end

function col(e,dx,dy)
 dx=dx or 0
 dy=dy or 0
	local x=mdx(e.x+dx-e.size/2)
	local y=mdy(e.y+dy-e.size/2)
	local ex=mdx(x+e.size-1)
	local ey=mdy(y+e.size-1)
 a={x,y,ex,y,ex,ey,x,ey}
 
 n=0
 for i=0,3 do
  x=a[i*2+1]/8
  y=a[i*2+2]/8
  local fr=lget(flr(x),flr(y))
  if n==0 and fget(fr,1) then
   n=1
  end
  if fget(fr,0) then 
   return 2
  end  
 end 
 return n
 
end

function dre(e)
 if not e.vis or e.dp!=dp then return end
	fr=e.fr
	x=e.x-e.size/2
	y=e.y+e.ofy-e.size/2
	
	
	--[[ focus circ ( need more tokens )
	if e.cfocus then
	 circ(e.x,e.y,e.cfocus,7)
	end
	--]]
	
	-- frame flag
	if fget(fr,0) then
	 y-=1
	end	
	if fget(fr,3) and e.t%4>2 then
	 fr+=1
		if fget(fr,2) then
		 kill(e)
		 return
		end	
		if fget(fr,1) then
			while not fget(fr-1,5) do
			 fr-=1
			end
		end	
	end
	e.fr=fr
	
	-- remap ball
	if e.blid then
	 pal(12,sget(16+e.blid,12))
	end
	-- remap
	if e.rmp then
	 for i=0,15 do
	  pal(i,sget(8+i,e.rmp))
	 end
	end
	if e.rmpo then
	 pal(e.rmpo[1],e.rmpo[2])
	end
	
	-- flh
	if e.flh then
	 for i=0,15 do
	  pal(i,e.flh)
  end
  if not tt then 
   e.flh=nil
  end
	end
	
	--
	if e.rainbow then
	 e.rainbow-=1
	 for i=0,15 do
	  pal(i,8+rand(8))
  end
	 if e.rainbow==0 then
	  e.rainbow=nil
	 end
	end
	
	--
	if e.stunshk then x+=1 end
	
	-- draw
	function dr(x,y) 
	 if e.lift then
   spr(64+e.lift.mt,x,y-6,1,1,e.flp==-1,-1)	
 	end
 	if e.rot then
   for gx=0,7 do for gy=0,7 do
	   px=(fr%16)*8
	   py=flr(fr/16)*8	 
	   p=sget(px+gx,py+gy)
	   if p>0 then
	    dx=gx
	    dy=gy	 
     for i=1,e.rot do
      dx,dy=7-dy,dx
     end
     pset(x+dx,y+dy,p)
    end
	  end	end
 	else
	  spr(fr,x,y,e.size/8,e.size/8,e.flp==-1)
	 end
	 if e.draw then e.draw(e,x,y) end
	end
 dr(x,y) 
 if e.lp then
  if x<8 then dr(x+120,y) end
  if x>120-e.size then dr(x-120,y) end
  if y<8 then dr(x,y+112) end
  if y>112-e.size then dr(x,y-112) end
 end
 
 pal()
end

function still(e)
 e.we=0
 e.vy=0
 e.vx=0
end

function spop(h,spd)
 return mka(h.x+rnd(8)-4,h.y+rnd(8)-4,40,5,3,3,5,spd)
end

function spawn_item(it)
 p=steal(bop)
 if p==nil then return end
 b=mkbonus(it,p)
 b.life=320
end

function drmap(lvl,dy)
 local bx=flr(lvl%8)*16
 local by=flr(lvl/8)*16
 map(bx,by,0,dy,15,14) 
 map(bx,by,120,dy,1,14)
 map(bx,by,0,112+dy,15,1)
 map(bx,by,120,112+dy,1,1)
end

function draw_lvl()
 -- boss
 if boss and boss.stp>0 then
  for i=0,2 do
  	spr(boss.hp>i and 242 or 243,50+i*9,118)
  end 
 end
 
 -- shake
 ddx=0
 if shk then
  shk=-shk
  shk*=0.75
  if abs(shk)<1 then
   shk=nil
  end
  ddx=shk
 end 
 camera(ddx,-8)
 
 if flash_bg then  
  rectfill(0,0,128,120,sget(tt+flash_bg-1,flash_bg))
 end
 
 
 -- next level
 if nxl then
  nxl+= (jump_lvl or 2)
  drmap(lvl-1,-nxl)
  drmap(lvl,120-nxl)
  if nxl>=120 then
   if jump_lvl and lvl<21 then
    jump_lvl-=1
    if jump_lvl==0 then
     jump_lvl=nil
    end
    leave()
    
   else
    nxl=nil
    init_level() 
   end

  end
 else
  drmap(lvl,0)

  for i=0,2 do
   dp=i
   foreach(ents,dre)
  end
 end

 -- inter
 camera()
 rectfill(0,0,127,7,0)
 
 for i=0,1 do
  h=heroes[i+1]  
  sc=h.score..""
  if not h.act and lives>0 then
   str="    press<a> to join   "
   index=flr(t/8)%#str
   str=str..str
   sc=sub(str,index,index+5)
  end
    
  while #sc<5 do sc="0"..sc end
  print(sc,108*i,1,7)
  
  if not congrats then
   px=23  
   for k=1,12 do
    l=letters[k]
    cl=1
    if l.act then 
     cl=t%24==k and 7 or 12
    end
		 	if success==flr((k-1)/6)then
		 	 cl=8+(t+k)%8
		 	end
    print(l.let,px,1,cl )
    px+=4
    if k==6 then
     px+=36
    end
   end
   lmax=min(lives,5)
   for l=0,lmax-1 do
    sspr(32,96,5,5, 64+l*6-(lmax*3) ,1)
   end
  end
  
 end

 -- congrats
 if congrats then
  str="congratulations"
  am=3+cos(t%80/80)*2
  for i=1,#str do
   print( sub(str,i,i), 32+i*4, 6+cos((t+i)%16/16)*am, 8+i%8)
  end  
 end
 
end


--[[
function log(str)
 add(logs,str)
 while #logs>20 do
  del(logs,logs[1])
 end
end
--]]

--#include main-functions