pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
pops={}

function makepop(x,y,size)
 local pop={}
 pop.x=x
 pop.y=y
 pop.size=size
 pop.life=1
 add(pops,pop)
 return pop
end

function _update()
 for i,pop in pairs(pops) do
  pop.life-=.4/pop.size
  if pop.life<0 then
   del(pops,pop)
  end
 end
 
 if btnp(4) then
  makepop(64+rnd(64),64+rnd(64),rnd(10))
 end
end

function _draw()
 cls()
 for i,pop in pairs(pops) do
  if pop.life>.7 then
   fillp()
  else
   fillp(0b1010010110100101)
  end
  circfill(pop.x,pop.y,
           pop.size*pop.life,
									  11,11)
	end
end
