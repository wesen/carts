function spawn_hero(h)
 add(ents,h)
 h.vis=true
 h.fr=34
 h.dead=false
 h.x=h.spx
 h.y=h.spy
 h.we=0.5
 h.frict=0.9
 h.upd=upd_hero
 h.phys=true
 h.lp=true 
 h.special=nil 
 
 if lt and lt>=time_limit then
  music(3)
 end
 lt=0
 for m in all(monsters) do
  if m.mad then
   m.mad=false
   m.rmp=nil
   --m.spd-=0.5
  end
 end
 --h.draw=draw_hero
end

--[[
function draw_hero(h,x,y)
 for i=1,h.powerballs do
  an= i/h.powerballs + (t%32)/32
  local r=12
  px=x+cos(an)*r
  py=y+sin(an)*r
  spr(47,px,py)
  for m in all(monsters) do
   adx=abs(px+4-m.x)
   ady=abs(py+4-m.y)
   if adx<6 and ady<6 then
    sfx(54)
    m.xpl()
    h.powerballs-=1
   end
  end
 end 
end
--]]

function upd_hero(h)
 if boss and boss.stp==0 then return end

 -- walking
 h.vx=0
 function walk(n)
  h.flp=n
  h.vx=n*1.5
 end  
 
 if btn(0,h.hid) then walk(-1) end
 if btn(1,h.hid) then walk(1) end
 
 -- jumping / anim
 if h.ground then 
  if btnp(4,h.hid) then
   sfx(35)
   h.vy=-7.5
   if btn(3,h.hid) then
    h.vy=2
    h.cgh=1
   end
  end
  h.fr=34
  if t%8<4 and h.vx!=0 then 
   h.fr=35 
  end
  if h.cdb then
   h.fr=38
   if h.cdb>2 then
    h.fr=39
   end   
  end
  
 else
  h.fr=35 
  if h.vy > 1 then
   h.fr=37
  end
  if h.vy < -1 then
   h.fr=36
  end  
 end

 -- autograb
 m=moncol(h)
 if m and m.stun and not h.lift then
  kill(m)
  h.lift=m
  sfx(38)
 end
 -- shooting / grab / drop
	if btn(5,h.hid) then
	 
	 if h.lift then	 
	  if h.ground and btn(3,h.hid) then
	   drop(h)   
	  else
	   launch(h)
	  end
	 --elseif #balls<h.ball0+3 then
  elseif not h.cdb then
   shoot_ball(h)
  end
 end
 
 -- invincible 
 h.vis=not h.cinv or h.cinv%2==1   
 
 -- special
 if h.special then
  if h.special==0 and t%4==0 and h.ground and h.vx!=0 then
   sfx(55)
   e=mke(-1,h.x,h.y)
   e.life=64
   e.t=rand(8)
   e.killmon=true   
   local flp=rand(2)==0
   e.draw=function(e,x,y)
    fr=flr(e.t/2)%4
    hh=min(e.t,min(8,e.life))
    sspr(fr*4,96,4,8,x+2,y+8-hh,4,hh,flp)
   end
  end
  if h.special==1 and t%2==0 then
   h.flh=8+flr(t/8)%8
   p=spop(h,4)
   p.lp=true
   p.vx=h.vx*rnd(0.5)
   p.vy=max(h.vy,-1.5)*rnd(0.5)
   p.blid=mod(2,4)
  end  
 end
end
