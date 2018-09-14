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

crs={}
draw_crs={}

function tick_crs(_crs)
 _crs=_crs or crs
 for cr in all(_crs) do
  if costatus(cr)!='dead' then
   _,err=coresume(cr)
   if (err!=nil) printh("error: "..err)
  else
   del(_crs,cr)
  end
 end
end

function add_cr(f,_crs)
 _crs=_crs or crs
 local cr=cocreate(f)
 add(_crs,cr)
 return cr
end

function cr_wait_for(t)
 while t>0 do
  yield()
  t-=dt
 end
end

-- b: beginning value
-- c: end value
-- t: current time
-- d: duration
function inoutcubic(b,c,t,d)
 t/=d
 local ts=t*t
 local tc=ts*t
 return b+c*(-2*tc+3*ts)
end

function incirc(b,c,t,d)
 t/=d;
 return -c*(sqrt(1-t*t)-1)+b;
end


parts_1={}
parts_2={}
parts_3={}

cls_particle=class(function(self)
 self.x=64
 self.y=64
 self.lifetime=1
 self.t=0
 self.radius=10
end)

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(parts_1,self)
   del(parts_2,self)
   del(parts_3,self)
  end
end

cls_p_band=subclass(cls_particle,function(self)
 cls_particle._ctr(self)
end)
function cls_p_band:draw()
 local v=incirc(1,self.radius,self.t,self.lifetime)
 circ(self.x,self.y,v,7)
end

cls_p_disc=subclass(cls_particle,function(self)
  cls_particle._ctr(self)
  self.lifetime=2
  self.radius=20
end)
function cls_p_disc:draw()
 -- local v=inoutcubic(1,self.radius,self.t,self.lifetime)
 local v=incirc(1,self.radius,self.t,self.lifetime)
 circfill(self.x,self.y,v,12)
end


function _init()
 add_cr(function()
  while true do
   add(parts_1,cls_p_disc.init())
   cr_wait_for(2)
  end
 end)
 add_cr(function()
  while true do
   add(parts_2,cls_p_band.init())
   cr_wait_for(.5)
  end
 end)
end

lasttime=time()
frame=0

function _update60()
 dt=time()-lasttime
 lasttime=time()

 tick_crs(crs)

 foreach(parts_1,function(p) p:update() end)
 foreach(parts_2,function(p) p:update() end)
 foreach(parts_3,function(p) p:update() end)
end

function _draw()
 cls()
 frame+=1

 tick_crs(draw_crs)
 foreach(parts_1,function(p) p:draw() end)
 foreach(parts_2,function(p) p:draw() end)
 foreach(parts_3,function(p) p:draw() end)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000a0aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
