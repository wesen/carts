fireflies={}

function fireflies_update()
 for p in all(fireflies) do
  p.counter+=p.speed
  p.life+=.3
  if (p.life>p.maxlife) p.life=0
 end
end

function fireflies_draw()
 for p in all(fireflies) do
  local x=p.x+cos(p.counter/128)*p.radius
  local y=p.y+sin(p.counter/128)*p.radius
  local size=abs(p.life-p.maxlife/2)/(p.maxlife/2)
  size*=p.size
  circ(x,y,size,10)
 end
end

function fireflies_init(v)
 fireflies={}
 for i=0,20 do
  local p={
   x=rnd(v.x),
   y=rnd(v.y),
   speed=(0.01+rnd(.1))*rndsign(),
   size=rnd(3),
   maxlife=30+rnd(50),
   life=0,
   counter=0,
   radius=60
  }
  p.life=rnd(p.maxlife)
  add(fireflies,p)
 end
end