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
 return v2(cos(angle),sin(angle))
end

local bboxvt={}
bboxvt.__index=bboxvt

function bbox(aa,bb)
 return setmetatable({aa=aa,bb=bb},bboxvt)
end

function bboxvt:w()
 return self.bb.x-self.aa.x
end

function bboxvt:h()
 return self.bb.y-self.aa.y
end

function bboxvt:is_inside(v)
 return v.x>=self.aa.x
 and v.x<=self.bb.x
 and v.y>=self.aa.y
 and v.y<=self.bb.y
end

function bboxvt:str()
 return self.aa:str().."-"..self.bb:str()
end

function bboxvt:draw(col)
 rect(self.aa.x,self.aa.y,self.bb.x-1,self.bb.y-1,col)
end

function bboxvt:to_tile_bbox()
 local x0=max(0,flr(self.aa.x/8))
 local x1=min(level.dim.x,(self.bb.x-1)/8)
 local y0=max(0,flr(self.aa.y/8))
 local y1=min(level.dim.y,(self.bb.y-1)/8)
 return bbox(v2(x0,y0),v2(x1,y1))
end

function bboxvt:collide(other)
 return other.bb.x > self.aa.x and
   other.bb.y > self.aa.y and
   other.aa.x < self.bb.x and
   other.aa.y < self.bb.y
end

function bboxvt:clip(p)
 return v2(mid(self.aa.x,p.x,self.bb.x),
           mid(self.aa.y,p.y,self.bb.y))
end

function bboxvt:shrink(amt)
 local v=v2(amt,amt)
 return bbox(v+self.aa,self.bb-v)
end

local hitboxvt={}
hitboxvt.__index=hitboxvt

function hitbox(offset,dim)
 return setmetatable({offset=offset,dim=dim},hitboxvt)
end

function hitboxvt:to_bbox_at(v)
 return bbox(self.offset+v,self.offset+v+self.dim)
end

function hitboxvt:str()
 return self.offset:str().."-("..self.dim:str()..")"
end

frame=0
dt=0
lasttime=time()
crs={}

player=nil

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

function add_cr(f)
 local cr=cocreate(f)
 add(crs,cr)
 return cr
end

function add_draw_cr(f)
 local cr=cocreate(f)
 add(draw_crs,cr)
 return cr
end

function wait_for(t)
 while t>0 do
  t-=dt
  yield()
 end
end


actor_cnt=0
actors={}

cls_actor=class(function(self,pos)
 self.pos=pos
 self.id=actor_cnt
 actor_cnt+=1
 self.spd=v2(0,0)
 self.is_solid=true
 self.hitbox=hitbox(v2(0,0),v2(8,8))
 add(actors,self)
end)

function cls_actor:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return self.hitbox:to_bbox_at(self.pos+offset)
end

function cls_actor:str()
 return "actor["..tostr(self.id)..",t:"..tostr(self.typ).."]"
end

function cls_actor:move(o)
 self:move_x(o.x)
 self:move_y(o.y)
end

function cls_actor:move_x(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   amount-=step
   if not self:is_solid_at(v2(step,0)) then
    self.pos.x+=step
   else
    self.spd.x=0
    break
   end
  end
 else
  self.pos.x+=amount
 end
end

function cls_actor:move_y(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   amount-=step
   if not self:is_solid_at(v2(0,step)) then
    self.pos.y+=step
   else
    self.spd.y=0
    break
   end
  end
 else
  self.pos.y+=amount
 end
end

function cls_actor:is_solid_at(offset)
 return solid_at(self:bbox(offset))
end

function cls_actor:collides_with(other_actor)
 return self:bbox():collide(other_actor:bbox())
end

function cls_actor:get_collisions(typ,offset)
 local res={}

 local bbox=self:bbox(offset)
 for actor in all(actors) do
  if actor!=self and actor.typ==typ then
   if (bbox:collide(actor:bbox())) add(res,actor)
  end
 end

 return res
end

function draw_actors(typ)
 for a in all(actors) do
  if ((typ==nil or a.typ==typ) and a.draw!=nil) a:draw()
 end
end

function update_actors(typ)
 for a in all(actors) do
  if ((typ==nil or a.typ==typ) and a.update!=nil) a:update()
 end
end

level=nil

cls_level=class(function(self)
end)

function cls_level:draw()
 rect(0,0,128,128,7)
end

function cls_level:bbox()
 return bbox(v2(0,0),v2(128,128))
end

function cls_level:update()
end

function cls_level:solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>128
  or bbox.aa.y<0
  or bbox.bb.y>128 then
   return true,nil
 else
  for e in all(self.environment) do
   if (bbox:collide(e:bbox())) return true,e
  end
  return false
 end
end

function solid_at(bbox)
 return level:solid_at(bbox)
end

cls_player=subclass(cls_actor,function(self)
 self.pos=v2(10,80)
 self.fly_button=cls_button.init(btn_fly,30)
 -- self.fire_button=cls_button.init(btn_fire,30)
 self.spd=v2(0,0)
 self.hitbox=hitbox(v2(0,0),v2(8,8))
 self.is_solid=true
 self.spr=35
 self.flip=v2(false,false)
 self.prev_input=0
 self.weight=0.5
 del(actors,self)
end)

function cls_player:draw()
 palt(7,true)
 spr(self.spr,self.pos.x,self.pos.y,1,1,not self.flip.x,self.flip.y)
 palt()
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

 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel)
 else
  self.spd.x=appr(self.spd.x,0,decel)
 end

 local maxfall=2
 local gravity=0.12*self.weight

 self.spr=35
 if self.fly_button.is_down then
  if self.fly_button:is_held() or self.fly_button:was_just_pressed() then
   self.spr=36
   self.spd.y=-1.2
   self.fly_button.hold_time+=1
  end
 end

 self.spd.y=appr(self.spd.y,maxfall,gravity)
 local dir=self.flip.x and -1 or 1

 self:move(self.spd)

 if input!=self.prev_input and input!=0 then
  printh("Update input")
  self.flip.x=input==-1
 end
 self.prev_input=input

 if btnp(btn_fire) then
  printh("FIRE")
  cls_projectile.init(self.pos+v2(0,8),v2(self.spd.x+dir*0.5,0))
 end
end

cls_camera=class(function(self)
 self.target=nil
 self.pull=16
 self.pos=v2(0,0)
 self.shk=v2(0,0)
 -- this is where to add shake
end)

function cls_camera:set_target(target)
 self.target=target
 self.pos=target.pos:clone()
end

function cls_camera:compute_position()
 return v2(self.pos.x-64+self.shk.x,self.pos.y-64+self.shk.y)
end

function cls_camera:abs_position(p)
 return p+self:compute_position()
end

function cls_camera:pull_bbox()
 local v=v2(self.pull,self.pull)
 return bbox(self.pos-v,self.pos+v)
end

function cls_camera:update()
 if (self.target==nil) return
 local b=self:pull_bbox()
 local p=self.target.pos
 if (b.bb.x<p.x) self.pos.x+=min(p.x-b.bb.x,4)
 if (b.aa.x>p.x) self.pos.x-=min(b.aa.x-p.x,4)
 if (b.bb.y<p.y) self.pos.y+=min(p.y-b.bb.y,4)
 if (b.aa.y>p.y) self.pos.y-=min(b.aa.y-p.y,4)
 self.pos=level:bbox():shrink(64):clip(self.pos)
 self:update_shake()
end

-- from trasevol_dog
function cls_camera:add_shake(p)
 local a=rnd(1)
 self.shk+=v2(p*cos(a),p*sin(a))
end

function cls_camera:update_shake()
 if abs(self.shk.x)+abs(self.shk.y)<1 then
  self.shk=v2(0,0)
 end
 if frame%4==0 then
  self.shk*=v2(-0.4-rnd(0.1),-0.4-rnd(0.1))
 end
end

cls_projectile=subclass(cls_actor,function(self,pos,spd)
 cls_actor._ctr(self,pos)
 self.spd=spd
 self.has_weight=true
 self.weight=1.2
 self.flip=v2(false,false)
 self.spr=6 -- bomb
 printh("projs pos "..self.pos:str())
end)

function cls_projectile:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

function cls_projectile:update()
 local maxfall=4
 local gravity=0.12*self.weight

 self.spd.y=appr(self.spd.y,maxfall,gravity)

 self.pos+=self.spd
 self.flip.x=self.spd.x<0

 if solid_at(self:bbox()) then
  printh("EXPLODE")
  del(actors,self)
 end
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
 player=cls_player.init()
 level=cls_level.init()
 main_camera=cls_camera.init()
 main_camera:set_target(player)
end

function _draw()
 frame+=1
 cls()

 local p=main_camera:compute_position()

 camera(p.x,p.y)
 level:draw()
 for actor in all(actors) do
  actor:draw()
 end
 player:draw()

end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
 player:update()
 for actor in all(actors) do
  actor:update()
 end

 main_camera:update()
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
77ccc777777777777777777777ccc777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a50007777ccc777777777777a500077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa00cc777a50007777777777aa00cc7777cccc110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a97c11c7aa0011c777777777a97c11c77a5001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77771117a97711177777777777771117aa00c1170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7777c1177777c117777777777777c11ca97cccc70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77979ccc77799ccc77777777777997777777cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777997770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77bbb777777777777777777777bbb777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a50007777bbb777777777777a500077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa00bb777a50007777777777aa00bb7777bbbb330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a97b33b7aa0033b777777777a97b33b77a5003330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77773337a97733377777777777773337aa00b3370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7777b3377777b337777777777777b33ba97bbbb70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77979bbb77799bbb77777777777997777777bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777997770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77888777777777777777777777888777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a80887777888777777777777a808877777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa8888777a80887777777777aa888877778888220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9782287aa88228777777777a97822877a8082220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77772227a97822277777777777772227aa8882270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77778227777782277777777777778228a97888870000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77979888777998887777777777799777777788880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777997770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77ccc777777777777777777777ccc777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ac0cc7777ccc777777777777ac0cc77777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aacccc777ac0cc7777777777aacccc7777cccc110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a97c11c7aacc11c777777777a97c11c77ac0c1110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77771117a97c11177777777777771117aaccc1170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7777c1177777c117777777777777c11ca97cccc70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77979ccc77799ccc77777777777997777777cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777997770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77bbb777777777777777777777bbb777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ab0bb7777bbb777777777777ab0bb77777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aabbbb777ab0bb7777777777aabbbb7777bbbb330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a97b33b7aabb33b777777777a97b33b77ab0b3330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77773337a97b33377777777777773337aabbb3370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7777b3377777b337777777777777b33ba97bbbb70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77979bbb77799bbb77777777777997777777bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777997770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
