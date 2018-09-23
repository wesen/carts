pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function class (init)
  local c = {}
  c.__index = c
  c._ctr=init
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    self.destroyed=false
    return self
  end
  c.destroy=function(self)
   self.destroyed=true
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,parent)
end

-- functions
function appr(val,target,amount)
 return (val>target and max(val-amount,target)) or min(val+amount,target)
end

function sign(v)
 return v>0 and 1 or v<0 and -1 or 0
end

function round(x)
 return flr(x+0.5)
end

function maybe(p)
 if (p==nil) p=0.5
 return rnd(1)<p
end

function mrnd(x)
 return rnd(x*2)-x
end

function rndsign()
 return rnd(1)>0.5 and 1 or -1
end

function rnd_elt(arr)
 local idx=flr(rnd(#arr))+1
 return arr[idx]
end


--- function for calculating
-- exponents to a higher degree
-- of accuracy than using the
-- ^ operator.
-- function created by samhocevar.
-- source: https://www.lexaloffle.com/bbs/?tid=27864
-- @param x number to apply exponent to.
-- @param a exponent to apply.
-- @return the result of the
-- calculation.
function pow(x,a)
  if (a==0) return 1
  if (a<0) x,a=1/x,-a
 local ret,a0,xn=1,flr(a),x
  a-=a0
  while a0>=1 do
      if (a0%2>=1) ret*=xn
      xn,a0=xn*xn,shr(a0,1)
  end
  while a>0 do
      while a<1 do x,a=sqrt(x),a+a end
      ret,a=ret*x,a-1
  end
  return ret
end

function palbg(col)
 for i=1,16 do
  pal(i,col)
 end
end

function bspr(s,x,y,flipx,flipy,col)
 palbg(col)
 spr(s,x-1,y,1,1,flipx,flipy)
 spr(s,x+1,y,1,1,flipx,flipy)
 spr(s,x,y-1,1,1,flipx,flipy)
 spr(s,x,y+1,1,1,flipx,flipy)
 pal()
 spr(s,x,y,1,1,flipx,flipy)
end

function bstr(s,x,y,c1,c2)
	for i=0,2 do
	 for j=0,2 do
	  if not(i==1 and j==1) then
	   print(s,x+i,y+j,c1)
	  end
	 end
	end
	print(s,x+1,y+1,c2)
end


-->8
cls_layer=class(function(self)
 self.target=nil
 self.particles={}
 self.emit_interval=.2
 self.t=0
 self.x=64
 self.x_jitter=0
 self.y=64
 self.y_jitter=0
 self.default_lifetime=1
 self.lifetime_jitter=0
 self.default_radius=3
 self.radius_jitter=0
 self.min_angle=0
 self.max_angle=1
 self.default_speed_x=1
 self.speed_jitter_x=0
 self.default_speed_y=1
 self.speed_jitter_y=0
 self.gravity=0.1
 self.default_weight=1
 self.weight_jitter=0
 self.fill=false
 self.col=7
 self.cols=nil
 self.grow=false
 self.trail_duration=0
 self.trails={}
 self.die_cb=nil
 self.emit_cb=nil
 self.default_damping=1
 self.damping_jitter=0
end)

function cls_layer:emit(x,y)
 if x==nil then
  if self.target!=nil then
   x=self.target.x
  else
   x=self.x
  end
 end
 if y==nil then
  if self.target!=nil then
   y=self.target.y
  else
   y=self.y
  end
 end

 local angle=self.min_angle+rnd(self.max_angle-self.min_angle)
 local spd_x=cos(angle)*self.default_speed_x+mrnd(self.speed_jitter_x)
 local spd_y=sin(angle)*self.default_speed_y+mrnd(self.speed_jitter_y)
 local weight=self.default_weight+mrnd(self.weight_jitter)

 local p={x=x+mrnd(self.x_jitter),
          y=y+mrnd(self.y_jitter),
          spd_x=spd_x,
          spd_y=spd_y,
          t=0,
          weight=weight,
          damping=self.default_damping+mrnd(self.damping_jitter),
          radius=self.default_radius+mrnd(self.radius_jitter),
          lifetime=self.default_lifetime+mrnd(self.lifetime_jitter)
         }
 add(self.particles,p)
 if (self.emit_cb!=nil) self.emit_cb(p)
 return p
end

function cls_layer:update()
 self.t+=dt
 if self.emit_interval!=nil and self.t>self.emit_interval then
  self.t=0
  self:emit()
 end
 for p in all(self.particles) do
  p.x+=p.spd_x
  p.spd_y+=p.weight*self.gravity
  p.y+=p.spd_y
  p.t+=dt
  p.spd_x*=p.damping
  p.spd_y*=p.damping
  if self.trail_duration>0 then
   local radius=p.radius*(1-p.t/p.lifetime)
   if (self.grow) radius=p.radius-radius
   add(self.trails,{
    x=p.x,
    y=p.y,
    t=0,
    radius=radius,
    lifetime=self.trail_duration
   })
  end
  if p.t>p.lifetime then
   if (self.die_cb!=nil) self.die_cb(p)
   del(self.particles,p)
  end
 end
 for trail in all(self.trails) do
  trail.t+=dt
  if trail.t>trail.lifetime then
   del(self.trails,trail)
  end
 end
end

function cls_layer:draw()
 for p in all(self.particles) do
  local col=self.col
  if col==nil then
   col=self.cols[flr(#self.cols*p.t/p.lifetime)+1]
  end
  local radius=p.radius*(1-p.t/p.lifetime)
  if (self.grow) radius=p.radius-radius
  if self.fill then
   circfill(p.x,p.y,radius,col)
  else
   circ(p.x,p.y,radius,col)
  end
 end

 for p in all(self.trails) do
  local col=self.col
  if col==nil then
   col=self.cols[flr(#self.cols*p.t/p.lifetime)+1]
  end
  local radius=p.radius
  if self.fill then
   circfill(p.x,p.y,radius,col)
  else
   circ(p.x,p.y,radius,col)
  end
 end
end


-->8

-->8

-->8

-->8

-->8

-->8
frame=0
lasttime=time()
dt=0

layers={}

mouse_pos={x=0,y=0}

function _init()

 poke(0x5f2d,1)

 local layer

 local blast_layer=cls_layer.init()
 blast_layer.emit_interval=nil
 blast_layer.col=7
 blast_layer.min_angle=0
 blast_layer.max_angle=0.5
 blast_layer.default_weight=0
 blast_layer.weight_jitter=0
 blast_layer.fill=true
 blast_layer.default_radius=10
 blast_layer.default_lifetime=0.1
 blast_layer.default_speed_x=0
 blast_layer.default_speed_y=0
 blast_layer.radius_jitter=5
 blast_layer.grow=true
 add(layers,blast_layer)

 layer=cls_layer.init()
 layer.x=64
 layer.y=0
 layer.emit_interval=0.1
 layer.col=nil
 layer.cols={8,9,10,10,7}
 layer.min_angle=-0.5
 -- layer.x_jitter=20
 layer.max_angle=0
 layer.default_weight=2
 layer.weight_jitter=2
 layer.fill=true
 layer.default_radius=2
 layer.default_lifetime=0.5
 layer.lifetime_jitter=0.1
 layer.radius_jitter=1
 layer.default_speed_x=1
 layer.speed_jitter_x=0.3
 layer.default_speed_y=1
 layer.speed_jitter_y=0.3
 layer.trail_duration=0.2
 layer.grow=true
 layer.die_cb=function(p)
  local blast=blast_layer:emit(p.x,p.y)
 end
 add(layers,layer)

 local dust_layer=cls_layer.init()
 dust_layer.gravity=0.0
 dust_layer.col=nil
 dust_layer.cols={7,10,9,8,2,1}
 dust_layer.emit_interval=nil
 dust_layer.default_lifetime=0.3
 dust_layer.default_speed_x=4
 dust_layer.default_speed_y=4
 dust_layer.default_damping=0.8
 add(layers,dust_layer)
 blast_layer.emit_cb=function(p)
  for i=0,5 do
   local _p=dust_layer:emit(p.x,p.y)
  end
 end

 layer.target=mouse_pos
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 mouse_pos.x=stat(32)
 mouse_pos.y=stat(33)

 for p in all(layers) do
  p:update()
 end
end

function _draw()
 frame+=1

 cls()
 rectfill(mouse_pos.x-2,mouse_pos.y-2,mouse_pos.x+2,mouse_pos.y+2,7)
 for p in all(layers) do
  p:draw()
 end

 print(tostr(stat(1)),0, 110,7)
end

__gfx__
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
