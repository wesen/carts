pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
actors={}

function makeball()
 local state_moving=0
 local state_waiting=1
 
 local self={
  x=flr(rnd(128)),
  y=flr(rnd(128)),
  radius=rnd(3)+3,
  color=flr(rnd(15))+1,
  state=state_moving,
  t=0,
  dt=0,
  dx=0,dy=0
 }
 self.speed=7-self.radius
 
 function self:draw()
  circfill(self.x,self.y,self.radius,self.color)
 end
 
 function self:wait_for(t)
  self.t=0
  self.dt=(1/t)/60 -- at 60 fps
  self.state=state_waiting
 end
 
 function self:move_to(x,y)
  self.t=0
  local distance=sqrt((x-self.x)^2+(y-self.y)^2)
  self.dt=self.speed/distance
  self.dx=(x-self.x)*self.dt
  self.dy=(y-self.y)*self.dt
  self.state=state_moving
 end
 
 function self:update()
  self.t+=self.dt
  
  if self.state==state_moving then
   if self.t<1 then
    self.x+=self.dx
    self.y+=self.dy
   else
    self:wait_for(rnd(2))
   end
  elseif self.state==state_waiting then
   if self.t>=1 then
	   self:move_to(flr(rnd(128)),flr(rnd(128)))
	  end
  end
 end

 self:move_to(flr(rnd(128)),flr(rnd(128)))
 
 add(actors,self)  
end
-->8

-->8

-->8

-->8

-->8

-->8

-->8

function _init()
 for i=1,32 do
  makeball()
 end
end

function _draw()
 cls()
 foreach(actors,function(a) a:draw() end)
end

function _update()
 foreach(actors,function(a) a:update() end)
end
