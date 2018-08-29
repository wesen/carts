pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
particles={}


function rndsign()
 return rnd(1)>0.5 and 1 or -1
end

function _update60()
 for p in all(particles) do
  p.counter+=p.speed
  p.life+=.3
  if (p.life>p.maxlife) p.life=0
 end
end

function _draw()
 cls()
 for p in all(particles) do
  local x=p.x+cos(p.counter/128)*p.radius
  local y=p.y+sin(p.counter/128)*p.radius
  local size=abs(p.life-p.maxlife/2)/(p.maxlife/2)
  size*=p.size
  circ(x,y,size,7)
  
 end
end

function _init()
 local w=128
 local h=128
 for i=0,20 do
  local p={
   x=rnd(w),
   y=rnd(h),
   speed=(0.05+rnd(.3))*rndsign(),
   size=rnd(5),
   maxlife=30+rnd(50),
   life=0,
   counter=0,
   radius=60
  }
  p.life=rnd(p.maxlife)
  add(particles,p)
 end
end
