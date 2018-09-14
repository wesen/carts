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

function angle2vec(a)
 return cos(a),sin(a)
end

function rndangle(a)
 return angle2vec(rnd(a or 1))
end

function copy_table(a)
 local res={}
 for k,v in pairs(a) do
  res[k]=v
 end
 setmetatable(res,getmetatable(a))
 return res
end

cls_particle=class(function(self)
 self.x=64
 self.y=64
 self.lifetime=1
 self.t=0
 self.radius=15
end)

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(parts_1,self)
   del(parts_2,self)
   del(parts_3,self)
  end
end

band_pal={7,7,7,15,15,10,10,9,9,8,8,8,2,2,2}
cls_p_band=subclass(cls_particle,function(self)
 cls_particle._ctr(self)
end)
function cls_p_band:draw()
 local v=inoutcubic(1,self.radius,self.t,self.lifetime)
 local col=flr(self.t/self.lifetime*#band_pal)
 circ(self.x,self.y,v,band_pal[col])
end

disc_pal={2,2,5,5,8,8,9,9,10,10,10}
cls_p_disc=subclass(cls_particle,function(self)
  cls_particle._ctr(self)
  self.lifetime=2
  self.radius=20
end)
function cls_p_disc:draw()
 -- local v=inoutcubic(1,self.radius,self.t,self.lifetime)
 local v=incirc(1,self.radius,self.t,self.lifetime)
 local col=disc_pal[flr((self.t/self.lifetime)*#disc_pal)]
 circfill(self.x,self.y,v,col)
end

pal={7,10,10,9,9,9,8,8,8,8,4,4,4,2,2,2,2}
cls_p_fly=class(function(self,angle)
 self.x=64
 self.y=64
 self.radius=3
 self.spd_x,self.spd_y=angle2vec(angle)
 self.spd_x*=0.5
 self.spd_y*=0.5
 self.x+=self.spd_x*self.radius
 self.y+=self.spd_y*self.radius
 self.lifetime=1
 self.trail_interval=.1
 self.t_trail=0
 self.t=0
end)

function cls_p_fly:update()
 cls_particle.update(self)
 self.t_trail+=dt
 if self.t_trail>self.trail_interval then
  self.t_trail=0
  local p=copy_table(self)
  p.spd_x*=0.3
  p.spd_y*=0.3
  p.trail_interval*=2
  p.lifetime/=2
  p.t/=2
  add(parts_3,p)
 end
 self.x+=self.spd_x
 self.y+=self.spd_y
 self.spd_x*=0.95
 self.spd_y*=0.95
end

function cls_p_fly:draw()
 local v=flr(self.t/self.lifetime*#pal)
 circ(self.x,self.y,.5,pal[v+1])
end

function particles_init()
 add_cr(function()
  local a=0
  while true do
   cr_wait_for(.4)
  end
 end)

 add_cr(function()
  local a=0
  while true do
   cr_wait_for(1)
   a+=0.4
   for i=a,30+a do
    add(parts_3,cls_p_fly.init(i/30))
   end
  end
 end)
 add_cr(function()
  while true do
   -- add(parts_2,cls_p_band.init())
   cr_wait_for(.5)
  end
 end)
end

cls_slider=class(function(self,name,x,y,val,min_v,max_v)
 self.x=x
 self.y=y
 self.val=val
 self.min_v=min_v
 self.max_v=max_v
end)

function cls_slider:draw()
 line(self.x,self.y,self.x+20,self.y,7)
 local sx=self.x+(self.val-self.min_v)/(self.max_v-self.min_v)*20
 rectfill(sx-1,self.y-3,sx+1,self.y+3,14)
end

function cls_slider:update()
end


parts_1={}
parts_2={}
parts_3={}
sliders={}

function _init()
 -- particles_init()
 add(sliders,cls_slider.init("foobar",20,20,0.5,0,1))
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
 foreach(sliders,function(s) s:update() end)
end

function _draw()
 cls()
 frame+=1

 tick_crs(draw_crs)
 foreach(parts_1,function(p) p:draw() end)
 foreach(parts_2,function(p) p:draw() end)
 foreach(parts_3,function(p) p:draw() end)
 foreach(sliders,function(s) s:draw() end)
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
0000000001010000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
