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
 for i=0,(v.x*v.y/20) do
  local p={
   x=rnd(v.x*8),
   y=rnd(v.y*8),
   speed=(0.01+rnd(.1))*rndsign(),
   size=rnd(3),
   maxlife=30+rnd(50),
   life=0,
   counter=0,
   radius=30+min(v.x,v.y)
  }
  p.life=rnd(p.maxlife)
  add(fireflies,p)
 end
end