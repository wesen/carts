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

