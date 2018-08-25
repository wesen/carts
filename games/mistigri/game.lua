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
