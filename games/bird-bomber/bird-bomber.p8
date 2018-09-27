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
    return self
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,{__index=parent})
end

-- functions
function appr(val,target,amount)
 return (val>target and max(val-amount,target)) or min(val+amount,target)
end

function sign(v)
 return v>0 and 1 or v<0 and -1 or 0
end

function rndsign()
 return rnd(1)>0.5 and 1 or -1
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

function rnd_elt(v)
 return v[min(#v,1+flr(rnd(#v)+0.5))]
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

function v_idx(pos)
 return pos.x+pos.y*128
end

-- vectors
local v2mt={}
v2mt.__index=v2mt

function v2(x,y)
 local t={x=x,y=y}
 return setmetatable(t,v2mt)
end

function v2mt.__add(a,b)
 return v2(a.x+b.x,a.y+b.y)
end

function v2mt.__sub(a,b)
 return v2(a.x-b.x,a.y-b.y)
end

function v2mt.__mul(a,b)
 if (type(a)=="number") return v2(b.x*a,b.y*a)
 if (type(b)=="number") return v2(a.x*b,a.y*b)
 return v2(a.x*b.x,a.y*b.y)
end

function v2mt.__div(a,b)
 if (type(a)=="number") return v2(b.x/a,b.y/a)
 if (type(b)=="number") return v2(a.x/b,a.y/b)
 return v2(a.x/b.x,a.y/b.y)
end

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:min(v)
 return v2(min(self.x,v.x),min(self.y,v.y))
end

function v2mt:max(v)
 return v2(max(self.x,v.x),max(self.y,v.y))
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:sqrmagnitude()
 return self.x^2+self.y^2
end

function v2mt:normalize()
 return self/self:magnitude()
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
end

function v2mt:flr()
 return v2(flr(self.x),flr(self.y))
end

function v2mt:clone()
 return v2(self.x,self.y)
end

dir_down=0
dir_right=1
dir_up=2
dir_left=3

vec_down=v2(0,1)
vec_up=v2(0,-1)
vec_right=v2(1,0)
vec_left=v2(-1,0)

function dir2vec(dir)
 local dirs={v2(0,1),v2(1,0),v2(0,-1),v2(-1,0)}
 return dirs[(dir+4)%4]
end

function angle2vec(angle)
 return cos(angle),sin(angle)
end

function do_bboxes_collide(a,b)
 return a.bbx > b.aax and
  a.bby > b.aay and
  a.aax < b.bbx and
  a.aay < b.bby
end

function do_bboxes_collide_offset(a,b,dx,dy)
 return (a.bbx+dx) > b.aax and
   (a.bby+dy) > b.aay and
   (a.aax+dx) < b.bbx and
   (a.aay+dy) < b.bby
end

glb_frame=0
glb_dt=0
glb_lasttime=time()
glb_crs={}
glb_particles={}

glb_player=nil

btn_right=1
btn_left=0
btn_fly=4
btn_fire=5

function tick_crs(crs_)
 for cr in all(crs_) do
  if costatus(cr)!='dead' then
   local status,err=coresume(cr)
   if (not status) printh("cr error "..err)
  else
   del(crs_,cr)
  end
 end
end

function add_cr(f,crs_)
 local cr=cocreate(f)
 add(crs_,cr)
 return cr
end

function cr_wait_for(t)
 while t>0 do
  t-=dt
  yield()
 end
end


glb_actors={}

cls_actor=class(function(self,x,y)
 self.x=x
 self.y=y
 self.spdx=0
 self.spdy=0
 self.is_solid=true
 self.hitbox={x=0.5,y=0.5,dimx=7,dimy=7}
 self:update_bbox()
 add(glb_actors,self)
end)

function cls_actor:update_bbox()
 self.aax=self.hitbox.x+self.x
 self.aay=self.hitbox.y+self.y
 self.bbx=self.aax+self.hitbox.dimx
 self.bby=self.aay+self.hitbox.dimy
end

function cls_actor:draw()
end

function cls_actor:update()
end

function cls_actor:move_x(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   local solid=solid_at_offset(self,step,0)
   local actor=self:is_actor_at(step,0)

   if solid or actor then
    if abs(step)<0.1 then
     self.spdx=0
     break
    else
     amount/=2
    end
   else
    amount-=step
    self.x+=step
    self.aax+=step
    self.bbx+=step
   end
  end
 else
  self.x+=amount
  self.aax+=amount
  self.bbx+=amount
 end
end

function cls_actor:move_y(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)

   local solid=solid_at_offset(self,0,step)
   local actor,a=self:is_actor_at(0,step)

   if solid or actor then
    if abs(step)<0.1 then
     self.spdy=0
     break
    else
     amount/=2
    end
   else
    amount-=step
    self.y+=step
    self.aay+=step
    self.bby+=step
   end
  end
 else
  self.y+=amount
  self.aay+=amount
  self.bby+=amount
 end
end

function cls_actor:is_actor_at(x,y)
 for actor in all(glbl_actors) do
  if (actor.is_solid and self!=actor and do_bbox_collide_offset(self,actor,x,y)) return true,actor
 end
 return false
end

glb_level=nil

cls_level=class(function(self)
 self.length=80
 self.environment={}
 self.background={}
 add(self.environment,cls_island.init(self.length))
end)

function cls_level:draw()
 for _,env in pairs(self.environment) do
  env:draw()
 end
end

function solid_at_offset(bbox,x,y)
 if (bbox.aay+y>120 or
     bbox.aay+y<-64 or
     bbox.aax+x<0 or
     bbox.aax+x>glb_level.length*8) then
  return true
 end
 for _,env in pairs(glb_level.environment) do
  if (do_bboxes_collide_offset(bbox,env,x,y)) return true
 end
 return false
end

-- cloud
cls_cloud=class(function(self,x,y,w,h)
 self.x=x
 self.y=y
 self.w=w
 self.h=h
end)

function cls_cloud:draw()
end
-- island

cls_island=class(function(self,length)
 self.tiles_top={}
 self.tiles={}
 for i=1,length do
  add(self.tiles,rnd_elt({102,103,104,105,106}))
  add(self.tiles_top,rnd_elt({86,87,88,89,90}))
 end
 self.aax=0
 self.aay=120
 self.bbx=length*8
 self.bby=128
end)

function cls_island:draw()
 for i=1,#self.tiles do
  spr(self.tiles_top[i],i*8,120-8)
 end
 palt(0,false)
 for i=1,#self.tiles do
  spr(self.tiles[i],i*8,120)
 end
 palt()
 -- rect(self.aax,self.aay,self.bbx,self.bby,8)
end

cls_player=subclass(cls_actor,function(self)
 cls_actor._ctr(self,10,80)
 self.fly_button=cls_button.init(btn_fly,30)
 -- self.fire_button=cls_button.init(btn_fire,30)
 self.is_solid=true
 self.spr=35
 self.fliph=false
 self.flipv=false
 self.prev_input=0
 self.weight=0.5
 del(glb_actors,self)
end)

function cls_player:draw()
 palt(7,true)
 spr(self.spr,self.x,self.y,1,1,not self.fliph,self.flipv)
 palt()
 -- rect(self.aax,self.aay,self.bbx,self.bby,8)
end

function cls_player:update()
 local input=btn(btn_right) and 1
    or (btn(btn_left) and -1
    or 0)

 self.fly_button:update()

 -- x movement
 local maxrun=1
 local accel=0.1
 local decel=0.01

 if abs(self.spdx)>maxrun then
  self.spdx=appr(self.spdx,sign(self.spdx)*maxrun,decel)
 elseif input != 0 then
  self.spdx=appr(self.spdx,input*maxrun,accel)
 else
  self.spdx=appr(self.spdx,0,decel)
 end

 local maxfall=2
 local gravity=0.12*self.weight

 self.spr=35
 if self.fly_button.is_down then
  if self.fly_button:is_held() or self.fly_button:was_just_pressed() then
   self.spr=36
   self.spdy=-1.2
   self.fly_button.hold_time+=1
  end
  if (self.fly_button:was_just_pressed()) sfx(14)
 end

 self.spdy=appr(self.spdy,maxfall,gravity)
 local dir=self.fliph and -1 or 1


 self:move_x(self.spdx)
 self:move_y(self.spdy)

 if input!=self.prev_input and input!=0 then
  self.fliph=input==-1
 end
 self.prev_input=input

 if btnp(btn_fire) then
  cls_projectile.init(self.x,self.y+8,self.spdx+dir*0.5,0)
  sfx(16)
 end
end

cls_camera=class(function(self)
 self.target=nil
 self.pull=16
 self.x=0
 self.y=0
 self.shkx=0
 self.shky=0
end)

function cls_camera:set_target(target)
 self.target=target
 self.x=target.x
 self.y=target.y
end

function cls_camera:compute_position()
 return self.x-64+self.shkx,self.y-64+self.shky
end

function cls_camera:abs_position(x,y)
 local posx,posy
 return x+self.x-64+self.shkx,y-64+self.shky+y
end

function cls_camera:pull_bbox()
 local v=v2(self.pull,self.pull)
 return {aax=self.x-self.pull,bbx=self.x+self.pull,aay=self.y-self.pull,bby=self.y+self.pull}
end

function cls_camera:update()
 if (self.target==nil) return
 local b=self:pull_bbox()
 local p=self.target
 if (b.bbx<p.x) self.x+=min(self.target.x-b.bbx,4)
 if (b.aax>p.x) self.x-=min(b.aax-p.x,4)
 if (b.bby<p.y) self.y+=min(p.y-b.bby,4)
 if (b.aay>p.y) self.y-=min(b.aay-p.y,4)
 self.x=mid(64,self.x,glb_level.length*8-64)
 self.y=mid(-64+64,self.y,128-64)
 self:update_shake()
end

-- from trasevol_dog
function cls_camera:add_shake(p)
 local a=rnd(1)
 self.shkx+=p*cos(a)
 self.shky+=p*sin(a)
end

function cls_camera:update_shake()
 if abs(self.shkx)+abs(self.shky)<1 then
  self.shkx=0
  self.shky=0
 end
 if glb_frame%4==0 then
  self.shkx*=-0.4-rnd(0.1)
  self.shky*=-0.4-rnd(0.1)
 end
end

cls_projectile=subclass(cls_actor,function(self,x,y,vx,vy)
 cls_actor._ctr(self,x,y)
 self.spdx=vx
 self.spdy=vy
 self.has_weight=true
 self.weight=1.2
 self.fliph=false
 self.flipv=false
 self.is_solid=false
 self.spr=6 -- bomb
end)

function cls_projectile:draw()
 spr(self.spr,self.x,self.y,1,1,self.fliph,self.flipy)
 -- rect(self.aax,self.aay,self.bbx,self.bby,8)
end

function cls_projectile:update()
 local maxfall=4
 local gravity=0.12*self.weight

 self.spdy=appr(self.spdy,maxfall,gravity)

 self:move_x(self.spdx)
 self:move_y(self.spdy)
 self.fliph=self.spdx<0

 if solid_at_offset(self,0,0) then
  glb_main_camera:add_shake(4)
  cls_boom.init(self.x,self.y,32,rnd_elt(glb_bomb_colors))
  sfx(12)
  del(glb_actors,self)
 end
end

glb_bomb_colors={7,8,8,8,8,9,9,9,7,7,7,9,13,14,15,6}
glb_dark={[0]=0,0,1,1,2,1,5,6,2,4,9,3,1,1,8,10}

cls_boom=class(function(self,x,y,radius,color,p)
 self.x=x
 self.y=y
 self.radius=radius
 self.original_color=color
 self.p=p or 1
 self.color=color+flr(rnd(2))*(glb_dark[color]-color)
 add(glb_particles,self)
end)

function cls_boom:update()
 if self.p==2 and self.radius>4 then
  for i=1,4 do
   local rx=mrnd(1.1*self.radius)
   local ry=mrnd(1.1*self.radius)
   cls_boom.init(
      mid(self.x+rx,0,127),max(self.y+ry,0),
      mrnd(0.5*self.radius),
      self.original_color)
  end

  for i=1,10 do
   cls_smoke.init(self.x,self.y,self.color)
  end
 end

 self.p+=1
 if (self.p>3) del(glb_particles,self)
end

function cls_boom:draw()
 if self.p==1 then
  circfill(self.x,self.y,self.radius,7)
 elseif self.p==2 then
  circfill(self.x,self.y,self.radius,self.color)
 else
  circ(self.x,self.y,self.radius+self.p-3,self.color)
 end
end

cls_smoke=class(function(self,x,y,color)
 self.x=x
 self.y=y
 self.color=color
 local ax,ay
 ax,ay=angle2vec(rnd(1))
 self.spdx=ax*(2+rnd(1))
 self.spdy=ay*(2+rnd(1))
 self.radius=1+rnd(3)
 self.color=color+flr(rnd(2))*(glb_dark[color]-color)
 add(glb_particles,self)
end)

function cls_smoke:draw()
 circfill(self.x,self.y,self.radius,self.color)
end

function cls_smoke:update()
 self.radius-=0.1
 self.x+=self.spdx
 self.y+=self.spdy
 self.spdx*=0.9
 self.spdy=0.9*self.spdy-0.1
 if (self.radius<0) del(glb_particles,self)
end



cls_button=class(function(self,btn_nr,max_hold_time)
 self.btn_nr=btn_nr
 self.is_down=false
 self.is_pressed=false
 self.down_duration=0
 self.hold_time=0
 self.ticks_down=0
 self.max_hold_time=max_hold_time
end)

function cls_button:update()
 self.is_pressed=false
 if btn(self.btn_nr) then
  self.is_pressed=not self.is_down
  self.is_down=true
  self.ticks_down+=1
 else
  self.is_down=false
  self.ticks_down=0
  self.hold_time=0
 end
end

function cls_button:was_just_pressed()
 return self.is_pressed
end

function cls_button:is_held()
 return self.hold_time>0 and self.hold_time<self.max_hold_time
end

function _init()
 glb_player=cls_player.init()
 glb_level=cls_level.init()
 glb_main_camera=cls_camera.init()
 glb_main_camera:set_target(glb_player)
 -- music(1)
end

function _draw()
 glb_frame+=1
 palt(0,false)
 cls(12)

 local camx,camy
 camx,camy=glb_main_camera:compute_position()
 --
 camera(camx,camy)
 glb_level:draw()
 for _,actor in pairs(glb_actors) do actor:draw() end
 for _,p in pairs(glb_particles) do p:draw() end
 glb_player:draw()

end

function _update60()
 glb_dt=time()-glb_lasttime
 glb_lasttime=time()
 tick_crs(glb_crs)
 glb_player:update()
 for _,actor in pairs(glb_actors) do actor:update() end
 for _,p in pairs(glb_particles) do p:update() end
 --
 glb_main_camera:update()
end


__gfx__
77888777777777777777777777777777777777770000000000700000000000000000000000000000000000000000000000000000000000000000000000000000
7a50007777888777777777777a500077777777770000000005770000000000000000000000000000000000000000000000000000000000000000000000000000
aa0088777a50007777777777aa008877778888220000000076770000000000000000000000000000000000000000000000000000000000000000000000000000
a9782287aa00228777777777a97822877a5002220000000007677000000000000000000000000000000000000000000000000000000000000000000000000000
77772227a97722277777777777772227aa0082270000000000067700000000000000000000000000000000000000000000000000000000000000000000000000
77778227777782277777777777778228a978888700000000000067e0000000000000000000000000000000000000000000000000000000000000000000000000
7797988877799888777777777779977777778888000000000000088e000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777997770000000000000088000000000000000000000000000000000000000000000000000000000000000000000000
77ccc777777777777777777777ccc777777777770000000000000000000000000000000000000000000000007c600000cc77c77c000000000000000000000000
7a50007777ccc777777777777a50007777777777000000000000000000000000000000000000000000000000c0dd000000cc0000000000000000000000000000
aa00cc777a50007777777777aa00cc7777cccc1100000000000000000000000000000000000000000000000070cc00000000cc00000004499499499400000000
a97c11c7aa0011c777777777a97c11c77a50011100000000005d000d0000000000000000d00000000000000070000000000000cc000444444444444400000000
77771117a97711177777777777771117aa00c117000000d65005566d0000000000000000600000000000000070d00000cc000000044441111111110000000000
7777c1177777c117777777777777c11ca97cccc70000056dd55655600000000000000000d650000000000000ccc0000000cc0000444114444444440000000000
77979ccc77799ccc77777777777997777777cccc00000505006dd500000000000000000050500000000000007ccc00000000cc00411444999999940000000000
777777777777777777777777777777777779977700000d0665d6d656000000000000000060d00000000000007cd0000077c777cc144994999119940000000000
77bbb777777777777777777777bbb777777777770000000600000000650000566000065660000000000000000000000000000000049494991111940000000000
7a50007777bbb777777777777a5000777777777700000605000000005d0000d55500d50050600000000000000000000000000000044994991111940000000000
aa00bb777a50007777777777aa00bb7777bbbb3300000556000000000d00006005506d0065500000000000000000000000000000049494999119940000000000
a97b33b7aa0033b777777777a97b33b77a500333000000dd0000000005500d50005d5000dd000000000000000000000000000000044994999444940000000000
77773337a97733377777777777773337aa00b337000000d60000000000d50600000500006d000000000000000000000000000000049494999999940000000000
7777b3377777b337777777777777b33ba97bbbb70000056d0000000000d5560000000000d6500000000000000000000000000000044994999999940000000000
77979bbb77799bbb77777777777997777777bbbb00000505000000000006d0000000000050500000000000000000000000000000033333bbbbbbbb0000000000
777777777777777777777777777777777779977700000d0600000000000000000000000060d00000000000000000000000000000044444444444440000000000
77888777777777777777777777888777777777770000d65665d6d65677c777c777c777c765d00000000000000000000000000000000000000000000000000000
7a80887777888777777777777a8088777777777700000500006dd500cccccd6ccccccd6c00600000000000000000000000000000000000000606000600000000
aa8888777a80887777777777aa8888777788882200005560d5565560dccd0cd6dccd0cd6d5560000000000000000000000000000000000006006666600000000
a9782287aa88228777777777a97822877a8082220000006d5005566d0c000cd00c000cd050050000000000000000000000000000000000006006565600000000
77772227a97822277777777777772227aa8882270000000d005d000d00c000000000000000500000000000000000000000000000000000006666797600000000
77778227777782277777777777778228a9788887000000000000000000000c000000000000000000000000000000000000000000000000000666777000000000
77979888777998887777777777799777777788880000000000000000000000000000000000000000000000000000000000000000000000000666666000000000
77777777777777777777777777777777777997770000000000000000000000000000000000000000000000000000000000000000000111006060606000000000
77ccc777777777777777777777ccc7777777777700000000000000000000000000000000000000006500005665d6d65600000000001776100000000000000000
7ac0cc7777ccc777777777777ac0cc7777777777000000000500000000000000000000000000000055500005500dd55500000000017777610000000000000000
aacccc777ac0cc7777777777aacccc7777cccc1100000500000005000000000000000000000000005000000dd506006500000000017777610000000000000000
a97c11c7aacc11c777777777a97c11c77ac0c11100000000005d000d000000000000000000000000d60000055500000d00000000177777761000000000000000
77771117a97c11177777777777771117aaccc117000500d65005566d000000000000000000000000d00000555000006d00000000177777761000000000000000
7777c1177777c117777777777777c11ca97cccc70000056dd55655600000000000000000000000005600605dd000000500000000177777761000000000000000
77979ccc77799ccc77777777777997777777cccc00000505006dd500000000000000000000000000555dd0055000055500000000177777761000000000000000
777777777777777777777777777777777779977700000d0665d6d656000000000000000000000000656d6d566500005600000000017777610000000000000000
77bbb777777777777777777777bbb7777777777700000006000000000000000000000000000000000000000065d0065600000000000000000000000000000000
7ab0bb7777bbb777777777777ab0bb77777777770005060500000000000000000000000000000000000000005000005500000000000000000900400400000000
aabbbb777ab0bb7777777777aabbbb7777bbbb33000005560000000000000000000000000000000000000000d500000500000000000000009004994900000000
a97b33b7aabb33b777777777a97b33b77ab0b333000000dd000000000000000000000000000000000000000050000d5d00000000000000009004414100000000
77773337a97b33377777777777773337aabbb337000050d600000000001000000000000000000000000000005d00006d0000000000000000044444e400000000
7777b3377777b337777777777777b33ba97bbbb70050056d0000000022100d00000000000000000000000000d550006500000000000000004446744700000000
77979bbb77799bbb77777777777997777777bbbb00000505000300002210ddd10030000000000000000000005560000500000000000000004444677000000000
777777777777777777777777777777777779977700000d06030303030100020030b0b0b000000000000000006000000600000000000000004040404000000000
00000000000000000000000000000000000000000000d65636333d33b6bbbdbbb6bbbdb336333d33b6bbbdbb656d6d5600000770000007700770000000000000
000000000000000000000000000000000000000000000500dbd5b5b5d3d53535d3d53535d3d53535dbd5b5b5005dd60000007777066077777777000000000000
00000000000000000000000000000000000000000050556055005ddd55005ddd55005ddd55005ddd55005ddd0650055d00007777677677777777600000000000
00000000000000000000000000000000000000000000006d0050d0500050d0500050d0500050d0500050d0500000500000776776777767766776776000000000
00000000000000000000000000000000000000000000500d50000000500000005000000050000000500000000500000007777777677666677677777600000000
00000000000000000000000000000000000000000000000000500500005005000050050000500500005005000000050077777677766776777767777700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677667766677766776600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666666066600666666666000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001d1e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0056575e004d585657583e582d2e56574d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65666768666968666968666768666769696a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010400083070033700377003c7003070033700377003c700007000070000700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050020183730c3530035307050183730c35330435080343f673246530c653007003067508014183730c35330634000003041500000183730c35300353070503c673246530c6530000030674080143c6733c613
01050020183730c3530035307050306750801430435080343f673246530c6530070030675080143c2330000030634000003041500000183730c35300353070503c673246530c6530000030674080143c6733c613
010500202017300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200730000000000000000000000000000000000000000000000000000000
010500202017300000000000000020173000000000000000000000000000000000000000000000201730000000000000000000000000201730000000000000000000000000000000000000000000000000000000
010500200711007220073300747008770080700807008073071110622105331044710277102073020730207300000000000000000000000000000000000000000000000000000000000000000000000000000000
010400203370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00203370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800203370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800203370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040808385143952139532395423a551395113852237532000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01070808385143952139532395423a551395113852237532000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010220203e6703e6603e6503c6503a6503764035640316302a630246202362023620226102261022610226102161021610206101f61018610146101361012610116100f6100e6100c6100a610076100761000000
010320203e6703e6603e6503c6503a6503764035640316302a630246202362023620226102261022610226102161021610206101f61018610146101361012610116100f6100e6100c6100a610076100761000000
0102040403624096500d6700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020606303503c3100000000000303503c3100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010120203a6703a6603a6603a5503a5503a55039440394403843037430364303533033330303302e3202b3202632023310203101d310113100631005310000000000000000000000000000000000000000000000
__music__
01 43020305
02 46010449
