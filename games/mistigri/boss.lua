
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

function bnext()

 boss.stp=1
 boss.lp=true
 wpx=16+rand(96)
 wpy=16+rand(96)
 tw(boss,wpx,wpy,-0.5,nil,bnext)
 --boss.sm=function(n) return 0.5-cos(n*0.5)*0.5 end
end
