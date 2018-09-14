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
 self.lifetime=slider_vals.lifetime
 self.trail_interval=slider_vals.trail_interval
 self.t_trail=0
 self.t=0
end)

function cls_p_fly:update()
 cls_particle.update(self)
 self.t_trail+=dt
 if self.t_trail>self.trail_interval then
  -- this is stupid, we should just reate particles with no speed and a lifetime
  self.t_trail=0
  local p=copy_table(self)
  local spd_factor=slider_vals.spd_factor
  p.spd_x*=spd_factor
  p.spd_y*=spd_factor
  p.trail_interval*=(self.lifetime*slider_vals.trail_interval_scale)
  p.t_trail=0
  p.lifetime/=slider_vals.lifetime_scale
  p.t/=(self.lifetime*3)
  add(parts_3,p)
 end
 self.x+=self.spd_x
 self.y+=self.spd_y
 self.spd_x*=slider_vals.spd_scale
 self.spd_y*=slider_vals.spd_scale
end

function cls_p_fly:draw()
 local v=flr(self.t/self.lifetime*#pal)
 circ(self.x,self.y,.5,pal[v+1])
end

function particles_init()
 printh("particles init")
 add_cr(function()
  local a=0
  while true do
   cr_wait_for(.4)
  end
 end)

 add_cr(function()
  local a=0
  while true do
   cr_wait_for(slider_vals.lifetime*2)
   a+=0.4
   local cnt=slider_vals.count
   for i=a,cnt+a do
    add(parts_3,cls_p_fly.init(i/cnt))
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

dragged_slider=nil
slider_vals={}

cls_slider=class(function(self,name,val,min_v,max_v)
 self.name=name
 self.x=0
 self.y=#sliders*10+10
 self.val=val
 self.min_v=min_v
 self.max_v=max_v
 self.bbox={
  aax=self.x,bbx=self.x+20,
  aay=self.y-3,bby=self.y+3
 }
 self.is_dragging=false
 printh("minv "..tostr(self.min_v))
 self:update()
end)

function fmt_dec(v)
 local fv=flr(v)
 local dec=flr((v-fv)*100)
 local res=tostr(fv)
 if (dec!=0) res=res.."."..(dec<10 and "0" or "")..tostr(dec)
 return res
end

function cls_slider:draw(mx,my,mb)
 line(self.x,self.y,self.x+20,self.y,7)
 local sx=self.x+(self.val-self.min_v)/(self.max_v-self.min_v)*20
 rectfill(sx-1,self.y-3,sx+1,self.y+3,14)
 print(fmt_dec(self.val),self.x+24,self.y-2,6)

 if (in_bbox(self.bbox,mx,my)) print(self.name,0,110)
end

function in_bbox(bbox,x,y)
 return x>=bbox.aax and x<=bbox.bbx and y>=bbox.aay and y<=bbox.bby
end

function cls_slider:update(mx,my,mb)
 -- bounding box for the knob
 if mb then
  if in_bbox(self.bbox,mx,my) and dragged_slider==nil then
   dragged_slider=self
  end
  if dragged_slider==self then
   local val=mid(self.min_v,
       (mx-self.x)/20*(self.max_v-self.min_v)+self.min_v,
       self.max_v)
   self.val=val
  end
 elseif dragged_slider==self then
  dragged_slider=nil
 end
 slider_vals[self.name]=self.val
end


parts_1={}
parts_2={}
parts_3={}
sliders={}

function _init()
 poke(0x5f2d, 1)
 add(sliders,cls_slider.init("count",30,1,40))
 add(sliders,cls_slider.init("spd_factor",0.3,0,3))
 add(sliders,cls_slider.init("lifetime",1,0,5))
 add(sliders,cls_slider.init("spd_scale",0.99,0.93,1.1))
 add(sliders,cls_slider.init("trail_interval",0.1,0.1,.5))
 add(sliders,cls_slider.init("trail_interval_scale",2,1.4,3))
 add(sliders,cls_slider.init("lifetime_scale",2,1,5))
 particles_init()
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
 local mx=stat(32)
 local my=stat(33)
 local mb=band(stat(34),1)==1
 foreach(sliders,function(s) s:update(mx,my,mb) end)
end

function _draw()
 local mx=stat(32)
 local my=stat(33)
 local mb=band(stat(34),1)==1

 cls()
 frame+=1

 tick_crs(draw_crs)
 foreach(parts_1,function(p) p:draw() end)
 foreach(parts_2,function(p) p:draw() end)
 foreach(parts_3,function(p) p:draw() end)
 foreach(sliders,function(s) s:draw(mx,my,mb) end)

 spr(1,mx,my)
 print(tostr(stat(1)),100,100)

 print(tostr(peek(0x5f80)),100,110)
end

__gfx__
00000000666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700066d670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000650567000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700500056700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001010000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
