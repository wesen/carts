pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
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

function _init()
 --logs={}
 ents={}
 t=0
 cartdata("mistigri")
 --init_hints()
 --init_hiscores()
 --init_game()
 init_menu()
end

hints="paleo...10altus...20ogre....30megano..50heavy..100ghost..500sunny..100vampi..200apple...50banana.100sberry.150orange.200grape..250wmelon.300cherry.350coco...400storm rod earrings  match     gong      bomb      magic belldoomcollarcornucopia+1 extra ball       +100% ball duration +50% ball speed     +1 big ball         +50% launch speed   +100% stun duration"


--
function init_hints()
 t=0
 function list(bfr,n,le,md,title)
  print(title,36,py,7)
  py+=8
  for i=0,7 do
   px=bx+flr(i/md)*56
   local y=py+(i%md)*10
   spr(bfr+i,px,y)
   print(sub(hints,k,k+le-1),px+10,y+3,8+(i+flr(t/4))%8)
   k+=le
  end
  py+=52
 end

 mdraw = function ()
  camera(0,t/8-16) --8
  py=0  
  print("extra lives at",40,0,8)
  for n in all(xtra_base) do
   py+=8
   print(n.." pts",48,py,7)
  end
  py=48
  bx=12
  k=1
  list(64,0,10,4, "---monsters---")
  list(48,1,10,4, "----fruits----")
  list(56,2,10,4, "----items-----")
  bx=28
  list(228,3,20,6,"---potions----")

  if t==1700 or btnp(5) then
   fadeto(init_menu,true)
  end
 end 
end
--]]

--[[
function init_hiscores()
 hi={} 
 n=0
 for i=0,9 do
  name=""
  score=dget(n+3)
  for h in all(heroes) do
   if h.score> dget(n+3) then
    
   end
  end
  n+=4
 end
 mdraw=draw_hiscores
end
function draw_hiscores()
 n=0
 for i=0,9 do
  name=""
  for k=0,2 do
   ch=dget(n)+1
   name=name..sub(alphabet,ch,ch)
   n+=1
  end
  
  score=dget(n)..""
  while #score<5 do
   score="0"..score
  end
  n+=1
  y=32+i*8
  print(i..">",14,y,6)
  print(name,24,y,7)
  print(".............",36,y,13)
  print(score,88,y,8+(i+t/4)%8)
 end
end
]]

function init_menu()
 
 reload()
 camera()
 x=0
 t=0
 if go!=0 then
  music(0)
 end
 go=0
 mdraw=draw_menu
 
end

function draw_menu()
 if go>0 then go+=1 end
 x=(x-0.25)%128
 for i=0,1 do
  map(96,32,x+i*128-128,8+go*go,16,14)
 end
 print("mistigri",0,120,1)
 for x=0,31 do for y=0,4 do		
		dx=max(40-(t-y)*3,0)*(x-15.5)
		if pget(x,y+120)==1 then
   sspr((t+x+y)%60<4 and 4 or 0,4,4,4,2+x*4+dx,1+y*4-go*go)
  end
 end end
 rectfill(0,120,127,127,0)

 pr=t%24<16
 if go>0 then pr=t%2<1 and go<39 end
 if pr then
  print("press x to start",32,121,7)
 end
  
 dy=max(go*go/32,0)
 spr(194,56,32+dy+cos(t%64/64)*4,2,2)

  
 if btn(5) and go==0 and not fade_n then
  sfx(61)
  music(-1)
  go=1
 end 
 
 if t==512 and go==0 then
  fadeto(init_hints,true)
 end
 
 if go==64 then
  init_game()
 end
end

function init_game()
 
 fadeto(pal,nil)
 monsters={}
 balls={}
 heroes={} 
 ents={}
 xtra=xtra_base

 blid=0
 lvb=0
 bnum=0
 big_fruit=48
 lives=3
 cornucopia=nil
 boss=nil
 
 -- letters
 letters={} 
 for n=1,12 do
  letters[n]={let=sub(words,n,n),act=false}
 end
 --for n=1,15 do add_let(n/2) end

 -- shuffle artefacts
 a={}
 apool={}
 for i=0,21 do
  add(a,mget(i,15))
 end
 while #a>0 do
  add(apool,steal(a))
 end 

 -- heroes
 act=1
 for i=0,1 do
  h=mke(34,0,0)
  del(ents,h)
  h.act=i==0   
  h.score=0
  h.hid=i
  if i==1 then 
   h.rmp=3
  end
  h.powerballs={}
  for i=0,5 do h["ball"..i]=1 end
  add(heroes,h)
 end
 
 goto_level(start_lvl)
 --nxl=0
 init_level()
 mdraw=draw_lvl
end


function init_level()
 clean=false
 lt=0--log(lvl)
 music(lvl==22 and 23 or 3)
 
 -- spawn
 for h in all(heroes) do
  if h.act then spawn_hero(h) end
 end

 -- items
 items={4}
 it=apool[1]
 del(apool,it)
 add(items,rand(128)==0 and 127 or it)
 --add(items,57)
 if cornucopia then
  cornucopia+=1
  dl(40,corn)  
 end

 --
 loop=upd_lvl
end

function goto_level(n)
 lvl=n
 
 --scan
 bop={}
 ggpos={}
 for x=0,14 do for y=0,13 do
  fr=lget(x,y)
  gfr=lget(x,(y+1)%14)
  px=x*8+4
  py=y*8+4
  if not fget(fr,0) and not fget(fr,1)
     and (fget(gfr,0) or fget(gfr,1) ) then
   add(ggpos,{x=px,y=py})
  end  
  
  if fr==34 or fr==35 then  
   h=heroes[fr-33]
   h.spx=px
   h.spy=py   
  elseif fr>=64 and fr<72 then
   mkm(fr-64,px,py)   
  elseif fr==4 then
   add(bop,{x=px,y=py})   
  end  
  
  if fget(fr,4) then
   lset(x,y,lget(0,14) )
  end
  
 end end
 
 --
 if lvl==22 then
  local e=mke(194,64,132)
  e.dp=2
  e.lp=false 
  e.size=16
  e.hp=3
  e.stp=0
  add(monsters,e)
  e.bad=true
  e.hit=function() end
  e.xpl=function(from)
   kill(from)
   if e.rainbow then return end
   e.hp-=1
   e.rainbow=24
   sfx(59)
   if e.hp==0 then
    for e in all(ents) do
     if e != boss and e.bad then 
      kill(e)
     end
    end 
    boss.upd=nil
    boss.twc=nil   
    dl(20,kill_boss)
   end
  end  
  tw(e,64,36,64,60,intro_boss)--64
  boss=e
 end
end

function kill_boss()
 --
 kill(boss)

 flash_bg=0
 tt=7
 shk=16
 
 -- mask part
 for i=0,3 do
  dx=i%2
  dy=flr(i/2)
  p=mke(194+dx+dy*16,boss.x+dx*8-4,boss.y+dy*8-4)
  p.vx=dx*2-1
  p.vy=dy*2-1
  p.life=80
  p.blink=40
  p.frict=0.92
  p.lp=false
 end
 
 -- parts
 for i=0,64 do
  f=function()
   p=spop(boss,2+rand(8))
   an=i/64
   impulse(p,an,8) 
   p.frict=0.85+rnd(0.14)  
  end  
  dl(rand(8),f)
 end
 sfx(60)
 
 --
 f=function()
  boss=nil
  congrats=true
  music(19)
  loop=upd_congrats
 end
 flowers={}
 dl(60,f)
 
end

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

function intro_boss() 
 boss.ban=0 
 boss.upd=upd_boss 
 blocks={}
 dl(40,add_block) --40
 --bnext()
end


function upd_boss(e) 
 e.ofy=cos(e.t%64/64-0.2)*6
 
 -- turning blocks
 e.ban-=0.01
 r=18
 k=0
 for b in all(blocks) do
  an=k/block_max+e.ban
  k+=1
  b.x=e.x+cos(an)*r
  b.y=e.y+e.ofy+sin(an)*r
  b.vis=true
 end
 

 if e.stp==0 then return end
 
 -- atk
 k=e.t%128
 boss.rmpo={1,sget(max(6-k/2,0),0)}
 if k==0 then
		boss_atk()
 end
  
end

function boss_atk()

 -- shoot
 if rand((gms()-1)*2)>0 then
  sfx(44)
  local e=badshot(104,boss)
  h=hcl(boss)
  an=sgda(h,boss)
  e.raymod=2
  impulse(e,an,1)
  e.frict=1.05
  e.turn=1
  e.upd=burning
  e.rmp=1
  return
 end

 -- spawn_monster
 sfx(49)
 p=steal(ggpos)
 add(ggpos,p)
 local e=mke(192,p.x,p.y)
 e.rmp=1
 e.life=120
 e.ondeath=function()
  if congrats then return end
  sfx(52)
  mt=rand(4)
  if mt==1 then mt=2 end
  mkm(mt,e.x,e.y)
 end
end

function burning(e)
 p=mka(e.x+rand(3)-1,e.y+rand(3)-1,24,12,4,4,4,2)
 p.rmp=e.rmp
end

function bnext()

 boss.stp=1
 boss.lp=true
 wpx=16+rand(96)
 wpy=16+rand(96)
 tw(boss,wpx,wpy,-0.5,nil,bnext)
 --boss.sm=function(n) return 0.5-cos(n*0.5)*0.5 end
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

function lget(x,y)
 return mget((lvl%8)*16+x,flr(lvl/8)*16+y)
end
function lset(x,y,n)
 return mset((lvl%8)*16+x,flr(lvl/8)*16+y,n)
end

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



function mod(md,lp)
 return flr(t/md)%lp
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

function hmod(n,md)
 n+=md
 n=n%(md*2)
 n-=md
 return n
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

function dst(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
	return sqrt(dx*dx+dy*dy)
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


function sgda(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
 return atan2(dx,dy)
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

function gameover()
 pal()
 t=0
 mdraw=function()
  rectfill(0,0,127,127,0)
  print("game over",46,62,sget(-sin(t/192)*7,1))
  if t==96 then
   init_menu()
  end
 end
 rectfill(0,0,127,127,0)
 

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

function rand(n)
 return flr(rnd(n))
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



function upd_lvl()


 -- ents
 if bnum==0 then lvb=0 end
	objs=0
 foreach(ents,upe)
 
 -- check gameover
 if act==0 then
  act=-1
  music(32)
  function f()
   loop=nil
   fadeto(gameover,true)
  end  
  dl(40,f) 
 end
 
 --
 if boss or congrats then return end
 
 if objs==0 and not clean then
  finish_lvl()
 end

 -- new player
 h2=heroes[2]
 if lives>0 and btnp(5,1) and not h2.act then
  lives-=1
  h2.act=true
  act+=1  
  spawn_hero(h2)
 end

 -- timer
 run_timer() 

end

function still(e)
 e.we=0
 e.vy=0
 e.vx=0
end

function finish_lvl()

 clean=true
 music(7)
 local kn=0
 for h in all(heroes) do
  if h.act then 
   kn+=1
   h.t=0
   still(h)
   h.lp=false
   h.phys=false
  
   local px=h.x
   local py=h.y
  
   h.upd=function()
    f=mod(2,8)
    h.fr=42+abs(4-f)
    h.flp=-sgn(4-f)
    h.x=px
    if h.flp==-1 then 
     h.x-=1 
    end
    h.y=py
    py+=h.t*0.1-1.5
    h.ondeath=function()
     kn-=1
     if kn==0 then
      leave()
     end
    end
    if t%2==0 and h.vis then
     p=spop(h,2)
     p.we=-rnd(0.2)
    end
   end
   
  end
 end
end

function leave()
 ents={}
 monsters={}
 nxl=0
 loop=nil
 goto_level(lvl+1)
end

function spop(h,spd)
 return mka(h.x+rnd(8)-4,h.y+rnd(8)-4,40,5,3,3,5,spd)
end

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


function _update()
  
 t+=1
 if tt then
  tt-=1
  if tt==0 then
   tt=nil
   flash_bg=nil
  end
 end
 if loop then
  loop() 
 end
 if nsfx then
  sfx(nsfx)
  nsfx=nil
 end
end


function spawn_item(it)
 p=steal(bop)
 if p==nil then return end
 b=mkbonus(it,p)
 b.life=320
end

function run_timer()
 lt+=1
 if gms()==0 then return end
  
 if #items>0 and rand(flr((time_limit-lt)/2))==0 then 
  spawn_item(steal(items))
 end
 
 if lt==time_limit then
  for m in all(monsters) do
   gomad(m)
  end
  local e=mke(-1,52,66)
  e.vy=-0.25
  e.draw=function(e,x,y)
   print("hurry up",x,y,7+(t%2))
  end
  e.life=44
  sfx(47)
  music(5)
 end
 if lt==time_limit+200 then
  sfx(51)
  mkm(5,64,64)
 end
end


function steal(a)
 local p=a[rand(#a)+1]
 del(a,p)
 return p
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

function _draw()
 cls()
 if mdraw then mdraw() end
 --draw_lvl()
 
 -- fade
 if fade_n then

  fade_n+=1
  n=fade_rev and fade_n or 15-fade_n
  for i=0,15 do
   pal(i,sget(8+i,4+flr(n/4)),1) 
  end
  --log(4+flr(n/4))
  if fade_n==15 then
   fade_nxt()
   fade_n=nil
   if fade_rev then
    fadeto(pal,false)
   end
  end 

 end  
 
 --[[ log 
 cursor(0,0)
 color(8+(t%8)) 
 color(8) 
 for l in all(logs) do
  print(l)
 end 
 --]]
end

--[[
function log(str)
 add(logs,str)
 while #logs>20 do
  del(logs,logs[1])
 end
end
--]]
__gfx__
1289a777113333b7ba7bbaba000d0000008822000cc000000ccc00000c7777000c7777c00000000000000000944294427666666d994499940aaaaa9000002210
1def7777011111c7cc7cccc70000d00008888220c7cc0000c7ccc000c7700000c777777c0007777c00000000444244426ddddddd44444442a7779a4211022211
3bababa7022282ef8efee8ef0002000088888222cccc0000ccccc0007700000077777000007777770000000722224442d111111129424442a779a44421122211
000000000133d567b9abcdef000020008888822d0cc00000ccccc0007000000077770000077777770000000700012221d99dd99d24422222a79a449411101110
feed777f001151d62493d2de000d00002888222d000000000ccc00007000000077700000077777770000000700000000d99dd99d22222222a9a4499201100000
edd17ffe0000105d1141515d0000d0002222222dc7c0c00c0010000070000000770000000777777700000077000000007666666622222294aa44994200011001
edd17ffe000000150020101500020000022222d0777c7cccc1c1010000000000c70000000777777c0000077c000000006ddddddd229422449449944200011000
d111feee000000010010000100002000002ddd00c7c0c00c00100000000000000c0000000c7777c0007777c000000000d1111111224422220244222000000000
0eeeef0077ee77ee08800000002000000400000000000040000020000000000000000000000000007666666d944294426777666d9aaaaa942992242211000011
e22222f08668866887880000000000000000000440000000000000000000000000070000000700006ddddddd444244426777666d99999994994422221d100111
22eef22f886688668888000000000009000000000000000090000000000700000007000000000000d1111111444244421d1001d1444444429444224201d11110
0e222f2ed22dd22d088000000900000000a000000000a0000000009000070000000000000000000001d1199d22222222017116102222111124422222001dd100
0e2e2e2e110011008bc94de688801210010000000cc0000000000000077777007700077070000070001d199d944294420016d1000221110022229422001d1100
0e2ee22e000000008ef200008898228212200100cccc0cc00cc000c000070000000000000000000000011666444244420016d100001110004222442901d11000
00e222e0000000003bac000089a9189802820020cccc0cc000c0000000070000000700000000000000001ddd4442444201711d1000000021422222241d100000
000eee000000000089abcd000898028200200000ccc00c000000000000000000000700000007000000000111222222221d1001d10000001122222222d1000000
000000000000c0000777770007777700077777000777770000777770007777700000000000000000077777000777770007777700077777000777770000000000
000c7c0000c000c0777777707777777077dd77d07777777007777777077777770777770000000000777777707777777077777770777777707777777000022000
00c000c00000000077dd77d077dd77d077dd77d0777777700777dd7607777dd777777770000000007dd7dd7077dd77d07777dd70777777d07777777000ee2200
007000700c00000c77dd77d077dd77d07777777077dd77d00777dd7607777dd777dd77d0000000007dd7dd7077dd77d07777dd70777777d07777777002e78820
00c000c000000000077777700777777007777d7057dd77d0007777770077777777dd77d000000000077777000777777007777770077777700777770002288820
000c7c0000c000c0005270704522757005225000052777700002870700002889077777700000000000727000005270700025277000225dd00022200000288200
000000000000c0000488240008882200488822000888727000088900000888000000707000000000042824000488240000884000058884000488840000022000
00000000000000000080800000000000000000000000000000800200008002000000000000000000008080000080800000080000008080000080800000000000
00040ab000000045000b0000000b00000b3022000b8888b00bbb000004444400000002420070007000000000007a990000dddd0f0047a40000dddd0000002200
0004b300000000940b3b88000a932400b3112d00b885858b00b30000466445400000041200d000d008800000079999900676d1f000a449000d0000d000000440
0888880000000aa903338e80a9a9994031221110b858588b00b030006776444400004201007000700880000079924900d777d11104a7a940d000000d2aa2009a
8fe888d00000aa79bb3888809a999940012d1220bb8888b300b03880777745450004200000d000d0004f0000a92a9055d676ddd109a7a99060000006a42a4a99
8ee882d0000aa79908e8e8e2a9a99940221112d0bbbbbb33088287887777444400220000077707770004f000a9499055dddddd1109a7a990702f820792894949
888822d000aa799d08888882999999402d1221103bbb33338788288d77774444022000000abb0abb00004f00999406001dddd1110444444007ff1870e8294944
82222d20499999d0008e8e22499994d00012d12203bb3330888d02d0477444402100000003b303b3000004f009907090011111109a7a99990081280088b34440
0dddd20054999d000000222004444d000000002d0033330008d00000044444001000000000000000000000400007090000111100000440000028820004334000
00007007000000000c0d00f005ddd50000555100067776d00070070000700700049444203bb3bb3307007000e880e88049999994777777760000000000066d66
0003fb3f000000000ccccf000c77c7700d7d55d00777776000aaa900e078780e04942210bbb3bbb300aaa90a82218221422222247ddddd6d0000000000666d66
003bbbbb000444000ccccd00c577577057175511d777716d7aaaaa9a2e7777e204942210b331333b0aaaaa9082218221424444447d66666d0000000006662212
0b3bbbbb004449400cc1c10005dddd005d7d5511677771610aa4a49022e7272204942210311bb1337a44a44001110111244444427d66666d000000006d612424
bb3babba044441400ccccd0005d555d9555522216777766609a4a4900222d2200494221013bbb3330944a449e880e880000000007d66666d0000000066224424
3333bbb02244449accc994d00c5ccc5915522811d777622da999999800dddd0004942210333333b30999999082218221000000007d66666d0000000066424424
1133377b444444990499940005ccc59901155510066668800099990000dddd000494221033113bbba099990082218221000000007666666d0000000066499999
130b70b7092222090c000d0005000500001111000d666dd00090080000d00d0002421110311133330009008001110111000000006ddddddd00000000dd444444
00000000000444000c0d00f005ddd5006ddddddd00676d000007007000700700003300006777666d6667666d06a6a6d0d11111107777777c0009400066212212
00007007004449400ccccf000c77c770ddd55dd56777776d70aaa90000787800033300006777666d6676667d66a6a6dd100000007888882c0099000066424424
0b33fb3f044441400ccccd00c5775770dd5555d5777771610aaaaa9000777700030003301d1001d16766677d0d9d9dd01000001078777c2c0990000066424424
bb3bbbbb2444449a0cc1c100055dddd9dd5555d5777771610aa4a49a0ee727e00001133301d11d107666777d000000001000001078782c2c4aaaaa4066424424
bb3bbbbb44444499cccccdd005555559ddd55dd577777666a9a4a490eee2d2ee010110000000000066677772000000001000001078722c2c00009900dd499999
333babba444442090cc994000ccccc99ddd55dd56777622609999990e2dddd2e1133110000000000667777d2011001101000001078cccc2c0009900066444444
3133bbb144442000c49994d055ccc550ddddddd5d666688d0099990800dddd02033300000000000067777dd201000100101111107222222c0049000066212212
0001377b442000000000000000000000d555555500d66d00090080000d0000d00000000000000000dddd22210000000000000000cccccccc0000000066424424
9999444400000000c0d0f0005ddd5000bb00aaa000777600070070000070070000002220a900a900a944a94433b33b33777677767cc17cc1e888e888d6666667
1212111100044400ccccd00077c7700000880a000777776000aaa90ae078780e00288882941494149414941433b33b33766d766dc111c11182288228ddddddd6
2424121200444940cc1c100099577000cc0880cc777776610aaaaa902e7777e2088aa980411441144114411433333b33766d766dc110c110828e828e1111111d
2424121204444140ccccd00059dd5000cc08800c777771617aa4a49022e7272208a55a804444444444444444bbbbbb3b6ddd6ddd0c100c0028e828e2d9911d10
242412122244449accc200005d555000c0e009907777766609a4a4990222d22008955a80a944a944a944a94433333333777677760c00000000000000d991d100
2424121244444499cc994d00ccccc0000eee0990677762260999999000dddd000289a8209414941494149414b3bbbbbb766d766d000000000000000066611000
9999444409222209049940005ccc5000b0ee000b06666660a09999000dddddd000888200411441144114411433b33333766d766d0000000000000000ddd10000
22221111000000000c000d0005000500bb0e0a0b00666600000900800000000000002000444444444444444433b3bb336ddd6ddd000000000000000011100000
e880e8804400000000c0d0f0005ddd500000000000000000000000000000000006ddddd0a900a9000000000033b3bb33777777767777777c1e88888100000000
822182212240000000ccccd000cc77c70000100000000c00000000000000000061111111941494140110011033a3a3337ddddd6d7111cc1ce888888809990000
822182212224440000cc1c10dc55775700000000010000000000000000999400d1d11d11411441140100010033766d9b7d66d66d711cc1c18822288209490000
011101112224494000ccccd00d55ddd000000000000000000010000000000900d11011014444444400000000ba6ddd137d6d766d71cc1cc188288e8209990000
00000000222241400cccc2000055555d00000000000000010000000000000900d11111110000000000000000316ddd9b7dd7d76d7cc1cccc88288e8200009000
011001102222449a00dc980000ccccc000c00000000000000000000000000900d1d11d110000000001100110badddd1b7d76d76d7c1ccc71888eee8200000900
0100010022244499004994c0005ccc50000000100c0000000000000000000000d110110100000000010001003119193367666d7d71ccc7c18888882200009490
00000000094440090c0000d00500005000000000000010000000000000000000011111100000000000000000333131336dddd16dcc11c1111822222100000900
00000000000000000000000000000000a5a5a5a5a5a5a5a5a5a59595959595a5949494949494949494949400000000940f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f
e1d1d1d1d100000000000000000000e19494949494940000000094949494949400000000000000000000000000000000b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4
00c6c6c6c6c6c6c6c6c6e7c5c5e7c600a5f100000000000000c50000000000a59400000085858585858585000040449400000000004d4d844d4d000000000000
e1000000f000000000000000004024e19494858585000000000085858594949400000000000000000000000000000000b40000000000000000000000000000b4
00e7000000000000000000000000c600a50000000000000000c50000003440a5944004000000858585850000b0b0b09400000000244044840040640000000000
e1440040f02400000000000000d1d1e1948500850000000000000000858585940000000000005c0d0d6c000000000000b40000000000000000000000000000b4
00c5000000000000444000000000c600a50000400044000000c50000a5a5a5a594b0b000000000040000000014000094000000004d4d4d844d4d4d0000000000
e1d1d1d1d1d1d1d1d100000000f000e1858500000000406400000085858585851f1f1f1f1f1f5d00006d1f1f1f1f1f1fb40000000000000000000000000000b4
00c500340000e6e6e6e6e6e60000c600a50000959595959595a5a5a5a5a5a5a5948585001400b0b0b0b000000000859400000000000000840000000000000000
e100000000000040f074000000f000e1858585000000c4c4c4c40000000085850f0f0f0f0f0f5d00006d0f5c0d0d6c0fb40000000000000000000000000000b4
00e7e6e600000000000000000000c600a50000000000f10000000000000000a59485000000000000000000000085859400000064000000840000002400000000
f000000000d1d1d1d1d1d10000f000f0850400000000000000000000008500000f0f5c0d0d0d0000006d0f5d00006d0fb40000000000000000000000000000b4
00c6000000000000000040000034c600a500340000f1001400000000000000a585000094000000000040000094b085850000004d4d4d4d844d4d4d4d00000000
f000240000f000000000f00000f000f0c4c4000000000000000000000000c4c40f0f5d00000000005c0d0d6c00006d0fb40000000000000000000000000000b4
00c600e6e6e600000000e6e6e6e6c600a5a595959500000000000000000000a585040094b0b0b00000b0b0b09485858500000000000000840000000000000000
d0d0d0d000f000000000f04024f0d0d0000004000000007c8c000000040000000d0d6c00000000005d00006d005c0d0db40000000000000000000000000000b4
00c6000000000000000000000000c600a5f100000000000000959595959595a5b0b0b09400000000000000859485b0b006002200000000000000000000320006
e1e1e1e1d1d1d10000d1d1d1d1d1e1e10000c4c40000007d8d340000c4c4000000006d00000000005d00006d005d0000b40000000000000000000000000000b4
00c6000000400400000000000000c600a500000000400000f1000000000000a59485850000000000000000008585859406c4c4c4c4c4c4c4c4c4c4c4c4c4c406
e1e1f0000000f00000f000000000f0e10000000000d4d4d4c7c7d4000000000000006d00005c0d0d6c00006d005d0000b40000000040040000004000000000b4
00c6000000e6e6e6e6e6e6000000e700a50000000095959500000000403200a59485040000400000000000000485859406000000000000000000000000000006
e1f000000000f00024f000000000f0e10000000000f0a7f0a7f0f000000000e100006d00005d00006d00005c0d6c0000b400000000b4b4b4b4b4b400000000b4
00c6000000000000000000000000c500a5000000f100000000a5a5a5a5a5a5a594b0b0b0b0b094b0b00000b0b0b0b09406000000000040240040000000000006
e1f0f00000d1d1d1d1d100000032f0e1e1f0f0f0f0d4f0a7f074d40000f0f0e1005c0d0d0d0000006d00005d006d0000b40000000000000000000000000000b4
40c6220000000000000000000032c500a50000f10000000000a50000000000a594f0000000f094850000000000858594000634000006c4c4c4c4060000340600
e1f0f00000f0000000f000d1d1d1d1e1e1f022f0d4d4740000f0d4d4f032f0e1005d0000000000006d00005d006d0000b40000000000000000000000000000b4
e6c6c6c6c6e7c5c5e7c6c6c6c6c6e700a500f1220000000000a50074000000a594f0220032f0948585000000000085941f1f060606061f1f1f1f060606061f1f
e100220000f0000000f000f0000000e1e1e1e1e1e1e100000000e1e1e1e1e1e10d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0db40022000000000000000000003200b4
0000000000000000000000000000000000a5a5a5a5a5a5a5a5a5c1c1c1c1c1a50094949494949494949494000000009400000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000002000000200777677767776770077700007777777e7777777e00066d6666d6600000000000000000000000000000000000000000000000000000000000
000000000020000077776776d666d66677777000eeeeeee2eeeeeee200666d6666d6660000000100000000000000000000000000000000000000000000000000
000200800000000077776776dd66d66677d7d0002220000000000222066622122122666000001110000000000000000000000000000000000000000000000000
20800020002000087766676776dddd660777700022000220022000226d612424424216d600001110000000000000000000000000000000000000000000000000
00200292008080207711167776d11166007070002022022002202202662244244244226600000000000000000000000000000000000000000000000000000000
0292089892920082771111676d111166000000002222000000002222664244244244246600110000000000000000000000000000000000000000000000000000
089828a8089202987711111761111166000000002222200000022222664999999999946600110000000000000000000000000000000000000000000000000000
28a8297829a828a87777177767717766000000002200200000020022dd444444444444dd00000000000000000000000000000000000000000000000000000000
7777777ee820000077776777666d6666777777772222000000002222662122122122126600d11100000000000000000000000000000000000000000000000000
eeeeeee288820000d7776777666d666d999999992022002222002202664244244244246600000000000000000000000000000000000000000000000000000000
0022220008220e8007766666ddddd660ffffffff2200002222000022664244244244246600d11100000000000000000000000000000000000000000000000000
00022000022008200671111111111660ffffffff2222200000022222664244244244246600000000000000000000000000000000000000000000000000000000
00000000000000000d711111111116d0ffffffff2202200000022022dd499999999994dd00d11100000000000000000000000000000000000000000000000000
0000000000e800000071177766611600f7f7f7f72000000000000002664444444444446600000000000000000000000000000000000000000000000000000000
000000000e820200006777776dd66600777777772202000000002022662122122122126600d11100000000000000000000000000000000000000000000000000
000000000222028000d6666ddddddd007f7f7f7f2200000000000022664244244244246600000000000000000000000000000000000000000000000000000000
0feeee800fe8fe800fe2fe800fe2fe80000440000004400000044000000440000004400000044000000000000000000000000000000000000000000000000000
f8888888f82e8888f82e2888f822e88800c22c0000c22c0000c22c0000c22c0000c22c0000c22c00000000000000000000000000000000000000000000000000
e8888882e8e88882e2e88821e2e1222100c71c0000c71c0000c71c0000c71c0000c71c0000c71c00000000000000000000000000000000000000000000000000
e8876882e88768828e8568e88e855ee80c1711c00c1711c00c1711c00c1711c00c1711c00c1711c0000000000000000000000000000000000000000000000000
e886d282e886d282f886d882f88d5882c2e8882cc4a9994cc3abbb3ccd7cccdcce7fffecc576665c000000000000000000000000000000000000000000000000
e8882282e8882182e882e282e221e282c282222cc494444cc3b3333ccdcddddccefeeeecc565555c000000000000000000000000000000000000000000000000
888888228882e8228882e8128ee2e812c282222cc494444cc3b3333ccdcddddccefeeeecc565555c000000000000000000000000000000000000000000000000
082222200821822008218220082182201cccccc11cccccc11cccccc11cccccc11cccccc11cccccc1000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000008080800008080000808080000808000000000000000000000000000000000000000000
11111111000110000000000000000000000000000000000000088800008888800008880800888880080888000000000000000000000000000000000000000000
11111111001001007777777677777776000000000000000000088800008888800008888800888880088888000000000000000000000000000000000000000000
11111111010110107222222d7000000d000000000000000000088800000030000000038800003000088300000000000000000000000000000000000000000000
11111111101111017288888d7011111d00000000000080000000b0000000b0000b000b000000b000000b00300000000000000000000000000000000000000000
11111111011111107288888d7011111d000000000000b0000000b0000ba0b03300a0b0000ba0b0330000b3300000000000000000000000000000000000000000
11111111111111116ddddddd6ddddddd0000300000b0b000003bb330003ab330003bb333003ab3300bbbb3000000000000000000000000000000000000000000
111111111111111100000000000000000000b0000003b3000003b3000003b3000003b3000003b3000033b3000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00feedfeedfeed0000feedfeedfeed00000000feedfeed0000feedfeedfeed0000feedfeedfeed00000000feedfeed0000feedfeedfeed0000feedfeedfeed00
00edd1edd1edd10000edd1edd1edd100000000edd1edd10000edd1edd1edd10000edd1edd1edd100000000edd1edd10000edd1edd1edd10000edd1edd1edd100
00edd1edd1edd10000edd1edd1edd100000000edd1edd10000edd1edd1edd10000edd1edd1edd100000000edd1edd10000edd1edd1edd10000edd1edd1edd100
00d111d111d1110000d111d111d11100000000d111d1110000d111d111d1110000d111d111d11100000000d111d1110000d111d111d1110000d111d111d11100
00feedfeedfeed00000000feed00000000feed0000000000000000feed000000000000feed00000000feed000000000000feed0000feed00000000feed000000
00edd1edd1edd100000000edd100000000edd10000000000000000edd1000000000000edd100000000edd1000000000000edd10000edd100000000edd1000000
00edd1edd1edd100000000edd100000000edd10000000000000000edd1000000000000edd100000000edd1000000000000edd10000edd100000000edd1000000
00d111d111d11100000000d11100000000d1110000000000000000d111000000000000d11100000000d111000000000000d1110000d11100000000d111000000
00feed0000feed00000000feed00000000feedfeedfeed00000000feed000000000000feed00000000feed000000000000feedfeed000000000000feed000000
00edd10000edd100000000edd100000000edd1edd1edd100000000edd1000000000000edd100000000edd1000000000000edd1edd1000000000000edd1000000
00edd10000edd100000000edd100000000edd1edd1edd100000000edd1000000000000edd100000000edd1000000000000edd1edd1000000000000edd1000000
00d1110000d11100000000d11100000000d111d111d11100000000d111000000000000d11100000000d111000000000000d111d111000000000000d111000000
00feed0000feed00000000feed0000000000000000feed00000000feed000000000000feed00000000feed0000feed0000feed0000feed00000000feed000000
00edd10000edd100000000edd10000000000000000edd100000000edd1000000000000edd100000000edd10000edd10000edd10000edd100000000edd1000000
00edd10000edd100000000edd10000000000000000edd100000000edd1000000000000edd100000000edd10000edd10000edd10000edd100000000edd1000000
00d1110000d11100000000d1110000000000000000d11100000000d111000000000000d11100000000d1110000d1110000d1110000d11100000000d111000000
00feed0000feed0000feedfeedfeed0000feedfeed000000000000feed00000000feedfeedfeed0000feedfeedfeed0000feed0000feed0000feedfeedfeed00
00edd10000edd10000edd1edd1edd10000edd1edd1000000000000edd100000000edd1edd1edd10000edd1edd1edd10000edd10000edd10000edd1edd1edd100
00edd10000edd10000edd1edd1edd10000edd1edd1000000000000edd100000000edd1edd1edd10000edd1edd1edd10000edd10000edd10000edd1edd1edd100
00d1110000d1110000d111d111d1110000d111d111000000000000d11100000000d111d111d1110000d111d111d1110000d1110000d1110000d111d111d11100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007777777e7777777e7777777e7777777e00000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000eeeeeee2eeeeeee2eeeeeee2eeeeeee200000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002220000000222200002222000000022200000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002200022000022000000220000220002200000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002022022000000000000000000220220200000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002222000000000000000000000000222200000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002222200000000000000000000002222200000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002200200000000000000000000002002200000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002222000000000000000000000000277767776777677000000000000000000000000000000000000000000000000000000000
1000000110000001100000011000202200220000000000000000220077776776d666d66610000001100000011000000110000001100000011000000110000001
0100001001000010010000100100220000220000000000000000220077776776dd66d66601000010010000100100001001000010010000100100001001000010
101001011010010110100101101022222000000000000000000000027766676776dddd6610100101101001011010010110100101101001011010010110100101
110110111101101111011011110122022000000000000000000000027711167776d1116611011011110110111101101111011011110110111101101111011011
11100111111001111110011111102000000000000000000000000000771111676d11116611100111111001111110011111100111111001111110011111100111
11111111111111111111111111112202000000000000000000000000771111176111116611111111111111111111111111111111111111111111111111111111
11111111111111111111111111112200000000000000000000000000777717776771776611111111111111111111111111111111111111111111111111111111
1111111111111111111111111111222200000000000000000000000077776777666d6666777e7777777e7777777e7777777e1111111111111111111111111111
11111111111111111111111111112022002200000000000000002200d7776777666d666deee2eeeeeee2eeeeeee2eeeeeee21111111111111111111111111111
1111111111111111111111111111220000220000000000000000220007766666ddddd66000000022220000222200000002221111111111111111111111111111
11111111111111111111111111112222200000000000000000000002267111111111166002200002200000022000022000221111111111111111111111111111
111111111111111111111111111122022000000000000000000000022d711111111116d202200000000000000000022022021111111111111111111111111111
11111111111111111111111111112000000000000000000000000000007117776661162200000000000000000000000022221111111111111111111111111111
11111111111111111111111111112202000000000000000000000000206777776dd6662220000000000000000000000222221111111111111111111111111111
1111111111111111111111111111220000000000000000000000000000d6666ddddddd0020000000000000000000000200221111111111111111111111111111
777e7777777e7777777e7777777e0000000000000000000000000000222211111111222200000000000000000000000022221111111111111111111111117777
eee2eeeeeee2eeeeeee2eeeeeee2000000000000000000000000220022021111111120220022000000000000000022002202111111111111111111111111eeee
00000022220000222200002222000000000000000000000000002200002211111111220000220000000000000000220000221111111111111111111111112220
02200002200000022000000220000000000000000000000000000002222211111111222220000000000000000000000222221111111111111111111111112200
02200000000000000000000000000000000000000000000000000002202211111111220220000000000000000000000220221111111111111111111111112022
00000000000000000000000000000000000000000000000000000000000211111111200000000000000000000000000000021111111111111111111111112222
20000000000000000000000000000000000000000000000000000000202211111111220200000000000000000000000020221111111111111111111111112222
20000000000000000000000000000000000000000000000000000000002211111111220000000000000000000000000000221111111111111111111111112200
000000000000000000000000000000000000000000007777777e7777777e7777777e7777777e0000000000000000000022221111111111111111111111112222
00220000000000000000000000000000000000000000eeeeeee2eeeeeee2eeeeeee2eeeeeee20000000000000000220022021111111111111111111111112022
00220000000000000000000000000000000000000000222000000022220000222200000002220000000000000000220000221111111111111111111111112200
20000000000000000000000000000000000000000000220002200002200000022000022000220000000000000000000222221111111111111111111111112222
20000000000000000000000000000000000000000000202202200000000000000000022022020000000000000000000220221111111111111111111111112202
00000000000000000000000000000000000000000000222200000000000000000000000022220000000000000000000000021111111111111111111111112000
00000000000000000000000000000000000000000000222220000000000000000000000222220000000000000000000020221111111111111111111111112202
00000000000000000000000000000000000000000000220020000000000000000000000200220000000000000000000000221111111111111111111111112200
777e000000000000000000000000000000000000000022220000000000000000000000002222000000007777777e7777777e7777777e7777777e7777777e7777
eee200000000000000000000000000000000000000002022002200000000000000002200220200000000eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeee
02220000000000000000000000000000000000000000220000220000000000000000220000220000000022200000002222000022220000222200002222000000
00220000000000000000000000000000000000000000222220000000000000000000000222220000000022000220000220000002200000022000000220000220
22020000000000000000000000000000000000000000220220000000000000000000000220220000000020220220000000000000000000000000000000000220
22220000000000000000000000000000000000000000200000000000000000000000000000020000000022220000000000000000000000000000000000000000
22220000000000000000000000000000000000000000220200000000000000000000000020220000000022222000000000000000000000000000000000000002
00220000000000000000000000000000000000000000220000000000000000000000000000220000000022002000000000000000000000000000000000000002
22220000000000000000000000000000000000000000222200000000000000000000000022220000000022220000000000000000000000000000000000000000
22020000000000000000000000000000000000000000202200220000000000000000220022020000000020220022000000000000000000000000000000002200
00220000000000000000000000000000000000000000220000220000000000000000220000220000000022000022000000000000000000000000000000002200
22220000000000000000000000000000000000000000222220000000000000000000000222220000000022222000000000000000000000000000000000000002
20220000000000000000000000000000000000000000220220000000000000000000000220220000000022022000000000000000000000000000000000000002
00020000000000000000000000000000000000000000200000000000000000000000000000020000000020000000000000000000000000000000000000000000
20220000000000000000000000000000000000000000220200000000000000000000000020220000000022020000000000000000000000000000000000000000
00220000000000000000000000000000000000000000220000000000000000000000000000220000000022000000000000000000000000000000000000000000
222200000000000000007777777e7777777e7777777e7777777e0000000000000000000022220000000022220000000000000000000000000000000000000000
22020000000000000000eeeeeee2eeeeeee2eeeeeee2eeeeeee20000000000000000220022020000000020220022000000000000000000000000000000002200
00220000000000000000222000000022220000222200000002220000000000000000220000220000000022000022000000000000000000000000000000002200
22220000000000000000220002200002200000022000022000220000000000000000000222220000000022222000000000000000000000000000000000000002
20220000000000000000202202200000000000000000022022020000000000000000000220220000000022022000000000000000000000000000000000000002
00020000000000000000222200000000000000000000000022220000000000000000000000020000000020000000000000000000000000000000000000000000
20220000000000000000222220000000000000000000000222220000000000000000000020220000000022020000000000000000000000000000000000000000
00220000000000000000220020000000000000000000000200220000000000000000000000220000000022000000000000000000000000000000000000000000
222200000000000000002222000000000000000000000000222200000000000000007777777e7777777e7777777e000000000000000000000000000000000000
22020000000000000000202200220000000000000000220022020000000000000000eeeeeee2eeeeeee2eeeeeee2000000000000000000000000000000002200
00220000000000000000220000220000000000000000220000220000000000000000222000000022220000000222000000000000000000000000000000002200
22220000000000000000222220000000000000000000000222220000000000000000220002200002200002200022000000000000000000000000000000000002
20220000000000000000220220000000000000000000000220220000000000000000202202200000000002202202000000000000000000000000000000000002
00020000000000000000200000000000000000000000000000020000000000000000222200000000000000002222000000000000000000000000000000000000
20220000000000000000220200000000000000000000000020220000000000000000222220000000000000022222000000000000000000000000000000000000
00220000000000000000220000000000000000000000000000220000000000000000220020000000000000020022000000000000000000000000000000000000
777e7777777e7777777e0000000000000000000000000000222200000000000000002222000000000000000022220000000000000000000000007777777e7777
eee2eeeeeee2eeeeeee2000000000000000000000000220022020000000000000000202200220000000022002202000000000000000000000000eeeeeee2eeee
22000022220000222200000000000000000000000000220000220000000000000000220000220000000022000022000000000000000000000000222000000022
20000002200000022000000000000000000000000000000222220000000000000000222220000000000000022222000000000000000000000000220002200002
00000000000000000000000000000000000000000000000220220000000000000000220220000000000000022022000000000000000000000000202202200000
00000000000000000000000000000000000000000000000000020000000000000000200000000000000000000002000000000000000000000000222200000000
00000000000000000000000000000000000000000000000020220000000000000000220200000000000000002022000000000000000000000000222220000000
00000000000000000000000000000000000000000000000000220000000000000000220000000000000000000022000000000000000000000000220020000000
00000000000000000000000000000000000000000000000022220000000000000000222200000000000000002222000000000000000000000000222200000000
00000000000000000000000000000000000000000000220022020000000000000000202200220000000022002202000000000000000000000000202200220000
00000000000000000000000000000000000000000000220000220000000000000000220000220000000022000022000000000000000000000000220000220000
00000000000000000000000000000000000000000000000222220000000000000000222220000000000000022222000000000000000000000000222220000000
00000000000000000000000000000000000000000000000220220000000000000000220220000000000000022022000000000000000000000000220220000000
00000000000000000000000000000000000000000000000000020000000000000000200000000000000000000002000000000000000000000000200000000000
00000000000000000000000000000000000000000000000020220000000000000000220200000000000000002022000000000000000000000000220200000000
00000000000000000000000000000000000000000000000000220000000000000000220000000000000000000022000000000000000000000000220000000000
777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777777e7777
eee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeeeeee2eeee
22000022220000222200002222000022220000222200002222000022220000222200002222000022220000222200002222000022220000222200002222000022
20000002200000022000000220000002200000022000000220000002200000022000000220000002200000022000000220000002200000022000000220000002
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000777077707770077007700000707000007770077000000770777077707770777000000000000000000000000000000000
00000000000000000000000000000000707070707000700070000000707000000700707000007000070070707070070000000000000000000000000000000000
00000000000000000000000000000000777077007700777077700000070000000700707000007770070077707700070000000000000000000000000000000000
00000000000000000000000000000000700070707000007000700000707000000700707000000070070070707070070000000000000000000000000000000000
00000000000000000000000000000000700070707770770077000000707000000700770000007700070070707070070000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000410000004040404020101010001020000000000080808050101020100080814110000040404000000000000004040404040404040000000000400000010111010101010100101000102010000000001010100000000020102000100000100000000000000000101010102020102000000280808020102000101010100
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002008080200000202000000000000000000020000000200000000000000000000000000000000040004040400000000000000000000080828080808080200000000
__map__
101010101010100000101010101010101b0b0b0b0b0b0b0b0b0b0b0b0b0b0b1b0e0e0e0e0e0e0e1d1d0e0e0e0e0e0e0e1c1c1c1c1c1c1c1c1c1c1c000000001e74000000001a0c0c0c6f000074007575780000787878787878787878780000787d7d7d7d7d7d00007d7d7d7d7d7d7d7d5d00005d5d5d5d5d5d5d5d5d5d00005d
030000000000034000030000000000031b7a7a7a7a7a7a7a7a7a7a7a7a7a7a1b0e0000000000000f0f0f00000000000e1e00000000000000000000000000001e00000000000000000000000000007475784400000000000000000000000044787d00000000000000000000000000007d5d00000000000000000000000000005d
030000000000111111110000000000031b7a7a7a7a7a7a7a7a7a7a7a7a7a7a1b0e000000000000400f0f0f040000000e1e00044200000000000000040000001e00000004004075000074760000000074786e6e6e6e0000000000006e6e6e6e787d00000004004000000000000000007d5d6e6e000000000000000000006e6e5d
030000000000030000030000000000031b7a7a7a7a7a7a7a7a7a7a7a7a7a7a1b0e00000000001d1d1d0e1d1d1d00000e1c1c1c1c000000000000001c1c1c1c1c00001a0c0c0c6f00001a6f0074000074780000000000000000000000000000787d0000006d6d6d6d6d6d6d6d0000007d5d00000000040043000004000000005d
030000000400030000030004000000031b7a047a7a407a7a7a7a407a7a047a1b0e000000000000000f0e0f000000000e1e0f1e0f000000000000000f1e1e1e1e00000000001f00000000007600000000780000000004004400000400000000787d00000000000000000000000000007d5d000000006e6e6e6e6e6e000000005d
100000001111110000111111000000101b0b0b0b0b0b7a7a7a7a0b0b0b0b0b1b0e00000000000000000e00000000000e1e1e0f0000000000400000000f1e1e1e7600000000410000000000040042000078000000006e6e6e6e6e6e00000000787d00400000000000000004004600007d5d00040000000000000000000004005d
100000000300000000000003000000101b7a7a7a7a7a7a7a7a7a7a7a7a7a7a1b0f00000000000000000e0000000000001e0f000000001d1d1d1d1d00000f1e1e00000000000000040000001a0c0c6f00780000000000000000000000000000787d6d6d6d0000000000007d7d6d6d6d7d5d6e6e6e6e5d000000005d6e6e6e6e5d
100040000300000404000003004000101b7a7a7a7a7a7a7a407a7a7a7a7a7a1b0f0f040000004100000e0f4000000f0f0f000000000000000000000000000f1e0000000074001a0c6f000000001f0000780000000044000000004400000000787d0000000000040046007d7d0000007d5d000000005d400000405d000000005d
101111111100001111000011111111101b7a7a7a0b0b0b0b0b0b0b0b7a7a7a1b0e0e0e0000000000000e1d1d1d1d0e0e0000000000400004000000000000000000000000007574740000000000000000780000007878780000787878000000787d0000006d6d7d7d6d6d00000000007d5d000000005d6e6e6e6e5d000000005d
000003000000000303000000000300001b7a7a7a7a7a7a7a7a7a7a7a7a7a7a1b0e0f000000000000000e0f0f0000000e0000001c1c1c1c1c1c0000000000000000000022767674767674760076237600780000000000000000000000000000787d00000000007d7d000000000000007d5d00000000000000000000000000005d
000003000000000303004000000300001b7a227a7a7a7a7a7a7a7a7a7a237a1b0e00000000000004000e0f042300000e00001c1f0000000000000000042342000c0c0c6f0000007676000000001a0c0c780000000400000000000004000000787d00000000000000000040000400007d5d00420000000000000000000042005d
111111000011111111111100001111111b0b0b0b0b0b7a7a7a7a0b0b0b0b0b1b0e00001d1d1d1d1d1d0e0e0e0e00000e1c1c1f00000000000000001c1c1c1c1c00760000007600000000007476000000786e6e787800007878000078786e6e787d6d6d6d0000000000006d6d6d6d007d5d6e6e6e6e6e6e00006e6e6e6e6e6e5d
100000000003000000000300000000101b7a7a7a7a7a7a7a7a7a7a7a7a7a7a1b0e000000000000000f0f0f0f0f00000e1e1e0f00000000000000000000000f0d00000000000000000000007600000000780000000000007878000000000000787d00000000000000000000000000007d00000000000000000000000000000000
100022000003000000000300002300101b7a04407a7a7a7a7a7a7a7a40047a1b0e0022000000400f0f0f0f0f0f00000e1e1e0f0f00220023000000000000000d00767400000000047640767500007674780000002200007878000023000000787d00220000000000000000000023007d00000000002200000000230000000000
001010101010100000101010101010107a0b0b0b0b0b0b0b0b0b0b0b0b0b0b1b000e0e0e0e0e0e1d1d0e0e0e0e0e0e0e001c1c1c1c1c1c1c1c1c1c000000000d00007600001a0c0c0c6f75747600747600000078787878787878787878000078007d7d7d7d7d00007d7d7d7d7d7d7d7d0000005d5d5d5d5d5d5d5d5d5d00005d
e4e4e4e4e5e5e6e7e7e8e83b3a3e3f3938e93d3d3d3d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d4d4d7c4d7c4c4c4c7c7c4d4d4d4d4d1e00000d0d0d0d1e1e0d0d0d0d00001e6b7b6b6b6b6b5b5b5b5b6b6b7b6b7b6b6a7a6969696a7a7a7a7a6a6969697a6a0c5c5c5c5c5c0c0c0c0c0c0c0c0c0c0c4b000000004b7a7a4b4b4b4b4b4b4b4b5d5d5d5d11115d5d5d5d5d5d5d5d5d5d54545454545454000054545454545454
4d00000000000000000000000041004d1e00000f0f0fc90f0f1e0f000000001e6b0000000000007a7a0000000000006b6a7a7a7a7a7a44047a7a7a7a7a7a7a6a0c00040000000000000041000000000c00000004444b7a7a4b000400000000005d00410000000000000000000000415d54000000000000000000000000000054
4d00000000044000000040040000004d1e430f0fc90000000f0f00000000001e6b4300000400007a7a0000040000436b7a7a7a7a7a7a797979797a7a7a7a7a7a0c00600044000000000000000000000c70707070704b7a7a00007070707070705d007a7a7a007a00007a7a7a007a005d54000064000000000000000064470054
7c0000004d6c6c6c6c6c6c6c4d00004d1e1d1d1d00000000000000000000431e6b5b5b5b5b5b007a7a005b5b5b5b5b6b7a7a7a427a7a7a7a7a7a7a427a7a7a7a0c4c4c4c4c4c0000000000000000410c007a7a7a7a7a7a0000007a7a7a0000005d007a007a007a0000007a00007a005d54006464640000000000006464640054
4d0004004d000000000000007c00007c1e0fc90000000000000440001d1d1d1e6b000000007a427a7a427a000000006b69797979797a7a7a7a7a7a79797979690c00000000000000000043000000000c0000427a7a7a000004007a42000000005d007a7a7a007a0000007a00417a005d54000064000000000000000064000054
4d4c4c4c4d000000004100004d00004d1e0000000000001d1d1d1d0f0f0f001e6b000000007a007a7a007a000000006b6a7a7a7a7a7a7a7a04447a7a7a7a7a6ad90000000000000041606000000000d9000070707070000070707070000000005d007a007a007a7a7a007a00007a005d5400ca64ca0000000000000064000054
5c0000005c000000000000007c00005c1ec90000000000000fc90f0fc900001e6b004600007a047a7a047a460000006b6a7a7a7a7a7979797979797a7a7a7a6ad90004000000000000606000040000d900007a7a7a0000007a7a7a00000000005d41040000000000410000000004005d5400cacaca0000000000000000004754
5c0000005c000000000000004d00005c1e0f0043000400000000c9000000001e00000000007a6b6b6b6b7a00000000006a7a7a7a7a7a7a7a7a7a7a7a7a7a7a6a0c0c0c5c5c5c5c5c5c0c0c0c0c0c0c0c4b4b7a7a004200007a7a00000000004b5d5d5d5d5d1111111111115d5d5d5d5d5400cacaca0400000000040000000054
5c0043005c000000000000004d00005c1e0f0f1d1d1d1dc9000000044300001e7a7a7a7a7a7a6b7b7b6b7a7a7a7a7a7a6a7a7a7a43047a7a7a43047a7a7a7a6ad90000000000000000000000000000d94b70707070707070707a7a707070704b5d00000000000000000000000000005d5400cacaca0b0b0b0b0b0b0000000054
4d4c4c4c4c7c0000000000005c4c4c4d1ec9000000000f0f0f1d1d1d1d00001e7b5b5b5b5b5b6b7b7b6b5b5b5b5b5b6b6a7a7a7a7969797a7a7969797a7a7a6ad90000000060600000000000000000d94b00000000000000007a7a7a7a00004b5d00000000040046000004000000005d5400ca47ca0000000000000000000054
4d000000004d0004000000005c00004d1e0000000000c9040f0f00000000001e7b000000007a6b6b6b6b7a000000006b6a7a7a7a7a6a7a7a7a7a6a7a7a7a7a6ad90040000060600000000400000000d94b00000000040022237a7a7a0000004b5d111111115d5d5d5d5d5d111111115d5400cacaca0400000000040000000054
5c000000004d4c4c4c7c00005c00005c1e00000000c90f0d0d0fc9000000001e6b000000007a007a7a007a000000007b6a7979797a6a7a7a7a7a6a7a7979796a0c0c0c0c0c0c0c0c0c0c0c5c5c0c0c0c4b000000004b7070707070700000004b5d00000000000000000000000000005d540b0b0b0b5454545454540b0b0b0b54
5c000000005c0000006c00005c00005c1e000000000f0f1e1e0f0fc90000001e6b6b6b7a7a7a007a7a007a7a7a6b6b6b6a7a7a7a7a6a7a7a7a7a6a7a7a7a7a6a0c00000000000000000000000000000c4b000000004b7a7a7a7a7a000000004b5d000000000000430000000000005d5d5400cacaca0000000000000000000054
5c002200005c0000007c00005c23005c1e0000220f0f0f1e1e0f0f0f2300001e6b7b6b220000007a7a000000236b7b6b6a7a227a7a6a7a7a7a7a6a7a7a237a6a0c00000000000000002200000023600c4b000000004b7a7a7a7a44004300004b5d00220000005d5d5d000023005d5d5d540022caca0000000000000000230054
004d4d4d4d4d4c4c4c4d4d4d4d4d4d4d000f0f0d0d0d0d1e1e1e0d0d0d0f0f1e006b6b6b6b6b5b5b5b5b6b6b6b6b6b6b7a006969696a7a7a7a7a6a696969006a005c5c5c5c5c0c0c0c0c0c0c0c0c0c0c00000000004b7a7a4b4b4b4b4b4b4b4b005d5d5d11115d5d5d5d5d5d5d5d5d5d00545454545454000054545454545454
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000110001f4051d4051c4051d0001d0001d0001d0001d0001d0001d0001d0001d0001d0001d0001d0001d0001d0001d0001d000000000000000000000000000000000000000000000000000000000000000
011000201d575130031d5252350524575242022452500505205752050520525205052257522505225251f2141b575005051b52500505225751f50522525005051f575005051f525005052057500505205251f214
014000002007224072240722007222071220622205222042270722407124072200721d0721d0721b0711b07220072240722407220072290712907227072270721d0721d0621d0521d0421d0321d0221d0121d002
011000001d5752d0322d0121857515575376051657516505185751d50511575005001307311505115751d505135752b0322b0121a5753763519505195751d50518575280322801200500376351f505115751d505
011000001557529032290121657518575000001a5751a5051857526032115751150513073000001157511505135752b0022b00215575135752b002155752b0021157529002280322903237635240020c57528002
010c00001d5752d0322d0121857515575376051657516505185751d50511575005001307311505115751d505135752b0322b0121a5753763519505195751d50518575280322801200500376351f505115751d505
010c00001557529032290121657518575000001a5751a5051857526032115751150513073000001157511505135752b0022b00215575135752b002155752b0021157529002280322903237635240020c57528002
01120000285753703229575390352b575300322d57218505295722954229532295222951200500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002d075180052d02529005290752400529075210052407521005290252100521075130052207518002220252b0052b075180022b025290052b0152900029072290252800028072280251d0022907229025
011000001d0751d0751d0751f07521075370051d07537005240752407524072260752407522075210751f0751d0751f075210721d07518075370051d07537005240752407524075260752407522075210751f075
01100000180751f275211752427518000242351810024225241052421524102265052420222005215021f1051d0051f505211021d00518205375051d50537505240052450524105265052420522005215051f505
01100000210751c2751d1750e27522275222352222522215222052200500005000050000500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001d575180351f54518035205351803522525180352457518035225451803520535180351f525180351d575180351f54518035205451803522525180352457518035225451803520535180351f52518035
011000001b575160351d575160351f575160352057516035225751603520575160351f575160351d575160351b575160351d575160351f575160352057516035225751603520575160351f575160351d57516035
012000003001530005300153000530015300053001530005300153000530015300053001530005300153000532015300053201530005320153000532015300052d015300052d015300052d015300052d01530005
01100000133730000013323000001331300000000000000036645306021f62500000000000000000000000001337300000133230000013313000000000000000366450000000000000001f645000000000000000
0120000021575245051850521575240001850521575225752457524000240001f57524000240001d5751c5751a5751d5751a5051a5751d575000001d5751f5752157500000000001c57500000000001557500000
012000001657518505185751a575000001c5751d5751f5752157500000245751d5750000000000215052157522575000002150521575000001d5051d5751d5051f57500000000000000000000000000000000000
012000002e015300052e0153000530015300053001530005350153200535015320053401539005340153900535015300003501530000350153000035015300003701530000370153000037015300003701500000
01100004340411d0212b03118061180001a200181001310324105290051d2052b005112032d0051d00300205262052e00524205222053560530005212053000521205002051f205350051d203356053400534005
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
018000001e0711b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001f0001d0001c0001a000180001a0001c0001d0001f0001d0001c0001a0001a000180001a0001c0001d0001c00018000180001a0001c00000000000000000000000000000000000000000000000000000
01100000070711f071243052b305243052b305243052b305243052b30500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002937529042293352902229325290122931500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001d3750c073290421d37518375326051d375003053261520375003052c0421f375326051d3751f3051b3750c0731b0422b3752c375326052e375003053261524375003053004227375326052437500305
01080000185351a005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100003261300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003424118141180001800018000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00003407100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002b2610c221000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000303752b2452b2151320500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001f0511f005182050c20500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003754100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000003750c372183711836218352183411834218342183411833118332183311832118322183211832118311183111831218312183001830018300183001830018300183001830018300183001830018300
010c00002b57500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f07524255211250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001327507275053150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002f67017371226401c6401963015630116300d6200b6200762005620036100261002610026100260001600000000000000000000000000000000000000000000000000000000000000000000000000000
010300003c0703003024030180300c0200c0200001000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002b65614561000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002d375393752d375393752d2052d005211052d205000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001f4752b235371250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000764407135000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200003761400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000112750c20011275112750c2720c2620c2520c2420c2320c2220c212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000000463346241f0020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000213731f6101f6501f6101f6301f6101f6201f610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800003507237175000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000075241f614000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001f44337111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000153751f3422d3221e105370021c0051330213302133021330213302133021330213302133021330213302133021330213302133021330213302133021320207002070022b0001f0001f0021f0021f002
010400001f4701f0211f0211f01113011130111f30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0130000037172072711f0051f0051f0051f0051f0051f005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000076731f4751a3750c275132350c265132250c255132150c245132150c2351f0150c2250c2050c21500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001307521132245753905524535390352452539025245153901500500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000747307403074231f60507413006051f60500600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000002b5712b525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01404344
01 01424344
02 01024344
01 03454344
02 04484344
01 05424344
02 06424344
04 07484344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 13424344
00 1b1c4344
01 100e4344
02 11124344
00 41424344
00 41424344
00 0c424344
00 0c424344
01 0c0f4344
02 0d0f4344
02 4e0c4344
00 1f424344
04 1e424344
04 0b424344
03 09424344
04 08424344

