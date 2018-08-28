pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
typ_player=0
typ_smoke=1
typ_bubble=2
typ_button=3
typ_spring=4
typ_spawn=5
typ_spikes=6
typ_room=7
typ_moving_platform=8
typ_particle=9
typ_moth=10
typ_camera=11
typ_lamp=12
typ_lamp_switch=13

flg_solid=0
flg_ice=1

btn_right=1
btn_left=0
btn_jump=4
btn_action=5

frame=0
dt=0
lasttime=time()
room=nil

actors={}
tiles={}
crs={}
jump_button_grace_interval=10
jump_max_hold_time=15

ground_grace_interval=12



function class (typ,init)
  local c = {}
  c.__index = c
  c._ctr=init
  c.typ=typ
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    c.typ=typ
    self.destroyed=false
    return self
  end
  c.destroy=function(self)
   self.destroyed=true
  end
  return c
end

function subclass(typ,parent,init)
 local c=class(typ,init)
 return setmetatable(c,parent)
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

-- intersects a line with a bounding box and returns
-- the intersection points
-- line is a bbox representing a segment
function isect(l,b)
 local res={}

 -- check if we can eliminate the bbox altogether
 local vmin=l.aa:min(l.bb)
 local vmax=l.aa:max(l.bb)
 if b.aa.x>vmax.x or
    b.aa.y>vmax.y or
    b.bb.x<vmin.x or
    b.bb.y<vmin.y then
  return {}
 end

 local d=l.bb-l.aa

 local p=function(u)
  return l.aa+d*u
 end

 local check_y=function(u)
  if u<=1 and u>=0 then
   local y1=l.aa.y+u*d.y
   if y1>=b.aa.y and y1<=b.bb.y then
    add(res,p(u))
   end
  end
 end
 local check_x=function(u)
  if u<=1 and u>=0 then
   local x1=l.aa.x+u*d.x
   if x1>=b.aa.x and x1<=b.bb.x then
    add(res,p(u))
   end
  end
 end

 local baa=b.aa-l.aa
 local bba=b.bb-l.aa
 if d.x!=0 then
  check_y(baa.x/d.x)
  check_y(bba.x/d.x)
 end
 if d.y!=0 then
  check_x(baa.y/d.y)
  check_x(bba.y/d.y)
 end

 return res
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
 local x1=min(room.dim.x,(self.bb.x-1)/8)
 local y0=max(0,flr(self.aa.y/8))
 local y1=min(room.dim.y,(self.bb.y-1)/8)
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

cls_camera=class(typ_camera,function(self)
 self.target=nil
 self.pull=16
 self.pos=v2(0,0)
 -- this is where to add shake
end)

function cls_camera:set_target(target)
 self.target=target
 self.pos=target.pos:clone()
end

function cls_camera:compute_position()
 return v2(self.pos.x-64,self.pos.y-64)
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
 self.pos=room:bbox():shrink(64):clip(self.pos)
end

function rspr(s,x,y,angle)
 angle=(angle+4)%4
 local x_=(s%16)*8
 local y_=flr(s/16)*8
 local f=function(i,j,p)
   pset(x+i,y+j,p)
 end
 if angle==1 then
  f=function(i,j,p)
   pset(x+7-j,y+i,p)
  end
 elseif angle==2 then
  f=function(i,j,p)
   pset(x+7-i,y+7-j,p)
  end
 elseif angle==3 then
  f=function(i,j,p)
   pset(x+j,y+7-i,p)
  end
 end
 for i=0,7 do
  for j=0,7 do
   local p=sget(x_+i,y_+j)
   if (p!=0) f(i,j,p)
  end
 end
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

-- tween routines from https://github.com/JoebRogers/PICO-Tween
function inoutquint(t, b, c, d)
 t = t / d * 2
 if (t < 1) return c / 2 * pow(t, 5) + b
 return c / 2 * (pow(t - 2, 5) + 2) + b
end

function inexpo(t, b, c, d)
 if (t == 0) return b
 return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end

function outexpo(t, b, c, d)
 if (t == d) return b + c
 return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end

function inoutexpo(t, b, c, d)
 if (t == 0) return b
 if (t == d) return b + c
 t = t / d * 2
 if (t < 1) return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
 return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end

function cr_move_to(obj,target,d,easetype)
 local t=0
 local bx=obj.pos.x
 local cx=target.x-obj.pos.x
 local by=obj.pos.y
 local cy=target.y-obj.pos.y
 while t<d do
  t+=dt
  if (t>d) return
  obj.pos.x=round(easetype(t,bx,cx,d))
  obj.pos.y=round(easetype(t,by,cy,d))
  yield()
 end
end
function tick_crs()
 for cr in all(crs) do
  if costatus(cr)!='dead' then
   coresume(cr)
  else
   del(crs,cr)
  end
 end
end

function add_cr(f)
 local cr=cocreate(f)
 add(crs,cr)
 return cr
end

actor_cnt=0

cls_actor=class(typ_actor,function(self,pos)
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

spr_moth=5

cls_moth=subclass(typ_moth,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.flip=v2(false,false)
 self.target=self.pos:clone()
 self.target_dist=0
 self.found_lamp=false
end)

tiles[spr_moth]=cls_moth

function cls_moth:get_nearest_lamp()
 local nearest_lamp=nil
 local dir=nil
 local dist=10000
 for _,lamp in pairs(room.lamps) do
  if lamp.is_on then
   local v=(lamp.pos-self.pos)
   local d=v:sqrmagnitude()/10000.
   if d<dist then
    if self:is_lamp_visible(lamp.pos) then
     dist=d
     dir=v
     nearest_lamp=lamp
    end
   end
  end
 end

 return nearest_lamp,dir
end

function cls_moth:is_lamp_visible(p)
 local ray=bbox(self.pos+v2(4,4),p)
 for tile in all(room.solid_tiles) do
  local p=isect(ray,tile)
  if (#p>0) return false
 end
 return true
end

function cls_moth:update()
 local nearest_lamp=self:get_nearest_lamp()
 if nearest_lamp!=nil then
  self.found_lamp=true
  self.target=nearest_lamp.pos+v2(4,4)
 elseif self.found_lamp then
  self.found_lamp=false
  self.target=self.pos:clone()
 end
 
 local maxvel=.3
 local accel=0.1
 local dist=self.target-self.pos
 self.target_dist=dist:magnitude()

 local spd=v2(0,0)
 if self.target_dist>1 then
  spd=dist/self.target_dist*maxvel
 end
 self.spd.x=appr(self.spd.x,spd.x,accel)+mrnd(accel)
 self.spd.y=appr(self.spd.y,spd.y,accel)+mrnd(accel)

 self:move(self.spd)

 self.spr=spr_moth+flr(frame/8)%3
end

function cls_moth:draw()
 if self.target_dist>3 and frame%16<8 then
  fillp(0b0011001111001100)
  line(self.pos.x+4,self.pos.y+4,self.target.x,self.target.y,5)
  fillp()
 end
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end
cls_button=class(typ_button,function(self,btn_nr)
 self.btn_nr=btn_nr
 self.is_down=false
 self.is_pressed=false
 self.down_duration=0
 self.hold_time=0
 self.ticks_down=0
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

function cls_button:was_recently_pressed()
 return self.ticks_down<jump_button_grace_interval and self.hold_time==0
end

function cls_button:was_just_pressed()
 return self.is_pressed
end

function cls_button:is_held()
 return self.hold_time>0 and self.hold_time<jump_max_hold_time
end
cls_room=class(typ_room,function(self,pos,dim)
 self.pos=pos
 self.dim=dim
 self.spawn_locations={}
 self.lamps={}
 self.solid_tiles={}

 room=self

 -- initialize tiles
 for i=0,self.dim.x do
  for j=0,self.dim.y do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   -- add solid tile bboxes for collision check
   if fget(tile,flg_solid) then
    add(self.solid_tiles,bbox(p*8,p*8+v2(8,8)))
   end
   if tile==spr_spawn_point then
    add(self.spawn_locations,p*8)
   end
   local t=tiles[tile]
   if (t!=nil) t.init(p*8,tile)
  end
 end
end)

function cls_room:bbox()
 return bbox(v2(0,0),self.dim*8)
end

function cls_room:get_friction(tile,dir)
 local accel=0.3
 local decel=0.2

 if (fget(self:tile_at(tile),flg_ice)) accel,decel=min(accel,0.1),min(decel,0.03)

 return accel,decel
end

function cls_room:draw()
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
end

function cls_room:spawn_player()
 cls_spawn.init(self.spawn_locations[1]:clone())
end

function cls_room:tile_at(pos)
 local v=self.pos+pos
 return mget(v.x,v.y)
end

function solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>room.dim.x*8
  or bbox.aa.y<0
  or bbox.bb.y>room.dim.y*8 then
   return true,nil
 else
  return tile_flag_at(bbox,flg_solid)
 end
end

function ice_at(bbox)
 return tile_flag_at(bbox,flg_ice)
end

function tile_at(x,y)
 return room:tile_at(v2(x,y))
end

function tile_flag_at(bbox,flag)
 local bb=bbox:to_tile_bbox()
 for i=bb.aa.x,bb.bb.x do
  for j=bb.aa.y,bb.bb.y do
   if fget(tile_at(i,j),flag) then
    return true,v2(i,j)
   end
  end
 end
 return false
end
spr_wall_smoke=54
spr_ground_smoke=51
spr_full_smoke=48
spr_ice_smoke=57
spr_slide_smoke=60

cls_smoke=subclass(typ_smoke,cls_actor,function(self,pos,start_spr,dir)
 cls_actor._ctr(self,pos+v2(mrnd(1),0))
 self.flip=v2(maybe(),false)
 self.spr=start_spr
 self.start_spr=start_spr
 self.is_solid=false
 self.spd=v2(dir*(0.3+rnd(0.2)),-0.0)
end)

function cls_smoke:update()
 self:move(self.spd)
 self.spr+=0.2
 if (self.spr>self.start_spr+3) del(actors,self)
end

function cls_smoke:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end
cls_particle=subclass(typ_particle,cls_actor,function(self,pos,lifetime,sprs)
 cls_actor._ctr(self,pos+v2(mrnd(1),0))
 self.flip=v2(false,false)
 self.t=0
 self.lifetime=lifetime
 self.sprs=sprs
 self.is_solid=false
 self.weight=0
 self.spd=v2(0,0)
end)

function cls_particle:random_flip()
 self.flip=v2(maybe(),maybe())
end

function cls_particle:random_angle(spd)
 self.spd=angle2vec(rnd(1))*spd
end

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(actors,self)
   return
 end

 self:move(self.spd)
 local maxfall=2
 local gravity=0.12*self.weight
 self.spd.y=appr(self.spd.y,maxfall,gravity)
end

function cls_particle:draw()
 local idx=flr(#self.sprs*(self.t/self.lifetime))
 local spr_=self.sprs[1+idx]
 spr(spr_,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

player=nil

cls_player=subclass(typ_player,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 -- player is a special actor
 del(actors,self)
 player=self
 main_camera:set_target(self)

 self.flip=v2(false,false)
 self.jump_button=cls_button.init(btn_jump)
 self.spr=1
 self.hitbox=hitbox(v2(2,0),v2(4,8))
 self.atk_hitbox=hitbox(v2(1,0),v2(6,4))

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0
end)

function cls_player:smoke(spr,dir)
 return cls_smoke.init(self.pos,spr,dir)
end

function cls_player:kill()
 player=nil
 room:spawn_player()
end

function cls_player:update()
 -- from celeste's player class
 local input=btn(btn_right) and 1
    or (btn(btn_left) and -1
    or 0)

 self.jump_button:update()

 local maxrun=1
 local accel=0.3
 local decel=0.2

 local ground_bbox=self:bbox(vec_down)
 local on_ground,tile=solid_at(ground_bbox)
 local on_ice=ice_at(ground_bbox)

 if on_ground then
  self.on_ground_interval=ground_grace_interval
 elseif self.on_ground_interval>0 then
  self.on_ground_interval-=1
 end
 local on_ground_recently=self.on_ground_interval>0

 if not on_ground then
  accel=0.2
  decel=0.1
 else
  if tile!=nil then
   accel,decel=room:get_friction(tile,dir_down)
  end

  if input!=self.prev_input and input!=0 then
   if on_ice then
    self:smoke(spr_ice_smoke,-input)
   else
    -- smoke when changing directions
    self:smoke(spr_ground_smoke,-input)
   end
  end

  -- add ice smoke when sliding on ice (after releasing input)
  if input==0 and abs(self.spd.x)>0.3
     and (maybe(0.15) or self.prev_input!=0) then
   if on_ice then
    self:smoke(spr_slide_smoke,-input)
   end
  end
 end
 self.prev_input=input

 -- x movement
 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel)
 else
  self.spd.x=appr(self.spd.x,0,decel)
 end
 if (self.spd.x!=0) self.flip.x=self.spd.x<0

 -- y movement
 local maxfall=2
 local gravity=0.12

 -- slow down at apex
 if abs(self.spd.y)<=0.15 then
  gravity*=0.5
 elseif self.spd.y>0 then
  -- fall down fas2er
  gravity*=2
 end

 -- wall slide
 local is_wall_sliding=false
 if input!=0 and self:is_solid_at(v2(input,0))
    and not on_ground and self.spd.y>0 then
  is_wall_sliding=true
  maxfall=0.4
  if (ice_at(self:bbox(v2(input,0)))) maxfall=1.0
  local smoke_dir = self.flip.x and .3 or -.3
  if maybe(.1) then
    local smoke=self:smoke(spr_wall_smoke,smoke_dir)
    smoke.flip.x=self.flip.x
  end
 end

 -- jump
 if self.jump_button.is_down then
  if self.jump_button:is_held()
    or (on_ground_recently and self.jump_button:was_recently_pressed()) then
   if self.jump_button:was_recently_pressed() then
    self:smoke(spr_ground_smoke,0)
   end
   self.on_ground_interval=0
   self.spd.y=-1.0
   self.jump_button.hold_time+=1
  elseif self.jump_button:was_just_pressed() then
   -- check for wall jump
   local wall_dir=self:is_solid_at(v2(-3,0)) and -1
        or self:is_solid_at(v2(3,0)) and 1
        or 0
   if wall_dir!=0 then
    self.jump_interval=0
    self.spd.y=-1
    self.spd.x=-wall_dir*(maxrun+1)
    self:smoke(spr_wall_smoke,-wall_dir*.3)
    self.jump_button.hold_time+=1
   end
  end
 end

 if (not on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

 self:move(self.spd)

 -- animation
 if input==0 then
  self.spr=1
 elseif is_wall_sliding then
  self.spr=4
 elseif not on_ground then
  self.spr=3
 else
  self.spr=1+flr(frame/4)%3
 end
end

function cls_player:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)

 --[[
 local bbox=self:bbox()
 local bbox_col=8
 if self:is_solid_at(v2(0,0)) then
  bbox_col=9
 end
 bbox:draw(bbox_col)
 bbox=self.atk_hitbox:to_bbox_at(self.pos)
 bbox:draw(12)
 print(self.spd:str(),64,64)
 ]]
end


spr_spring_sprung=66
spr_spring_wound=67

cls_spring=subclass(typ_spring,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox=hitbox(v2(0,5),v2(8,3))
 self.sprung_time=0
end)
tiles[spr_spring_sprung]=cls_spring
tiles[spr_spring_wound]=cls_spring

function cls_spring:update()
 -- collide with player
 local bbox=self:bbox()
 if self.sprung_time>0 then
  self.sprung_time-=1
 else
  if player!=nil then
   if bbox:collide(player:bbox()) then
    player.spd.y=-3
    self.sprung_time=10
    local smoke=cls_smoke.init(self.pos,spr_full_smoke,0)
   end
  end
 end
end

function cls_spring:draw()
 local spr_=spr_spring_wound
 if (self.sprung_time>0) spr_=spr_spring_sprung
 spr(spr_,self.pos.x,self.pos.y)
end
spr_spawn_point=1

cls_spawn=subclass(typ_spawn,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.target=self.pos
 self.pos=v2(self.target.x,128)
 self.spd.y=-2
 add_cr(function()
  self:cr_spawn()
 end)
end)

function cls_spawn:cr_spawn()
 cr_move_to(self,self.target,1,inexpo)
 del(actors,self)
 cls_player.init(self.target)
 cls_smoke.init(self.pos,spr_full_smoke,0)
end

function cls_spawn:draw()
 spr(spr_spawn_point,self.pos.x,self.pos.y)
end
spr_spikes=68

cls_spikes=subclass(typ_spikes,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox=hitbox(v2(0,3),v2(8,5))
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:update()
 local bbox=self:bbox()
 if player!=nil then
  if bbox:collide(player:bbox()) then
   player:kill()
   cls_smoke.init(self.pos,32,0)
  end
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.pos.x,self.pos.y)
end
cls_moving_platform=subclass(typ_moving_platform,cls_actor,function(pos)
 cls_actor._ctr(self,pos)
end)
spr_lamp_off=98
spr_lamp_on=96

spr_lamp_nr_base=84

cls_lamp=class(typ_lamp,function(self,pos,tile)
 self.pos=pos
 self.is_on=tile==spr_lamp_on
 -- lookup number in tile below
 self.nr=room:tile_at(self.pos/8+v2(0,1))-spr_lamp_nr_base
 add(room.lamps,self)
 add(actors,self)
end)

tiles[spr_lamp_off]=cls_lamp
tiles[spr_lamp_on]=cls_lamp

function cls_lamp:draw()
 local spr_=self.is_on and spr_lamp_on or spr_lamp_off
 spr(spr_,self.pos.x,self.pos.y,2,2)
end

spr_switch_on=69
spr_switch_off=70

cls_lamp_switch=subclass(typ_lamp_switch,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.hitbox=hitbox(v2(-3,-3),v2(11,11))
 self.is_solid=false
 -- lookup number in tile above
 self.nr=room:tile_at(self.pos/8+v2(0,-1))-spr_lamp_nr_base
 self.is_on=tile==spr_switch_on
 self.player_near=false
end)

tiles[spr_switch_off]=cls_lamp_switch
tiles[spr_switch_on]=cls_lamp_switch

function cls_lamp_switch:update()
 self.player_near=player!=nil and player:collides_with(self)
 if self.player_near and btnp(btn_action) then
  self:switch()
 end
end

function cls_lamp_switch:switch()
 for lamp in all(room.lamps) do
  if lamp.nr==self.nr then
   lamp.is_on=not lamp.is_on
   self.is_on=lamp.is_on
  end
 end
end

function cls_lamp_switch:draw()
 local spr_=self.is_on and spr_switch_on or spr_switch_off
 spr(spr_,self.pos.x,self.pos.y)
 if self.player_near then
  print("x",self.pos.x+2,self.pos.y-10,7)
 end
end

-- fade bubbles
-- x gravity
-- x downward collision
-- x wall slide
-- x add wall slide smoko
-- x fall down faster
-- x wall jump
-- x variable jump time
-- x test controller input
-- x add ice
-- x springs
-- x wall sliding on ice
-- x player spawn points
-- x spikes
-- x respawn player after death
-- x add ease in for spawn point
-- x add coroutine for spawn point
-- x slippage when changing directions
-- x flip smoke correctly when wall sliding
-- x particles with sprites
-- x fix world collision / falling off world
-- x add moving / pulling camera

-- x add moth sprites
-- x instantiate moth
-- x add light / light switch mechanic
-- x add moth following light
-- x move moth to nearest light
-- better moth movement
-- x ray collision with moth to find nearest visible lamp
-- x switches can toggle multiple lamps
-- better lamp switches
-- bresenham dashed line
-- add checkpoints
-- show tutorial text above switch
-- moth animation when seeing light
-- better darker tiles
-- exit door
-- draw moth above light
-- add fireflies flying around
-- particles trailing moth

-- readd gore on death
-- add fire as a moth obstacle

-- add simple intro levels

-- add frogs

-- x make wider levels
-- x implement camera
-- enemies
-- moving platforms
-- laser beam
-- vanishing platforms

-- parallax background
-- add death mechanics
-- camera shake
-- fades

-- music
-- sfx

--include main-test
main_camera=cls_camera.init()

function _init()
 cls_room.init(v2(16,0),v2(32,16))
 room:spawn_player()
end

function _draw()
 frame+=1

 cls()
 local p=main_camera:compute_position()
 camera(p.x,p.y)

 room:draw()
 draw_actors()
 if (player!=nil) player:draw()
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs()
 if (player!=nil) player:update()
 update_actors()
 main_camera:update()
end


__gfx__
0000000000ddd0000000000000ddd00000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000dd7670000ddd0000dd767000dd767000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700dd7575700dd76700dd757570dd75757000d00d000d0000d0000000000000000000000000000000000000000000000000000000000000000000000000
0007700007757570dd75757007757570077575700005500000d00d000dd00dd00000000000000000000000000000000000000000000000000000000000000000
00077000007777000775757000777700007777000058d8000558d800055550000000000000000000000000000000000000000000000000000000000000000000
00700700000990000077770000044000000999600500d0000000d0000008d8000000000000000000000000000000000000000000000000000000000000000000
000000000004400000044000006006000004460000000000000000000000d0000000000000000000000000000000000000000000000000000000000000000000
00000000000660000006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ff0ff0000000000f000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0990009900f00f0000f00f000fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0095959000ffff0000ffff000cfc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009990000fcfc00f0fcfc0066e66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009e900f0ffffe0f0fffef00f6f00f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000009f0099000f0044f000fff00f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099909f0ffff00f0fff0000fff00f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009444900fffff400ff6f60005f5ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000800088008408000008800000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008480008400080000000000008e8000008e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008888800d0000d00000000000888880008e8800000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00488480000000000000000000288280000882000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000
000444000880000800000000000222000000200000020000000e0000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d800d808000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d00d008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000770700000770000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
70000600007700667000007000000000000000000000000000060000007700007000000000000000000000000000000000000000000000000000000000000000
00770000006600000000006700000000000000000000000000000700006000006600000000000000000000000000000000000000000000000000000000000000
07766000000000000000000000000000000000000000000000707700000000000000700000000000000000000000000000000000000000000000000000000000
0677770000000000000000000000000000000000000000000777770007007000000060000000000007000000c00000000000000007000000c000000000000000
077776000000000700000000007770000000770000000070006676007700600000000000000c0000c60000000000007007000000c60000000000007000000000
0076600700700000000000700777600077006770070000600000660006700000070000000077c0000c00770000000000c6000c000c0077000000000000000000
0000000676607000070007607667770076000660000000000000060000000000060000000c766cc0000006c0000000000c00c7c0000006c00000000000000000
33333333666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44433544776677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9444554477c67c760000000000000000000000000066650000666500000000000000000000000000000000000000000000000000000000000000000000000000
44444449ccc677760000000000000000070007000088850000666500000000000000000000000000000000000000000000000000000000000000000000000000
44594444ccc6cccc0566665000000000070007000062650000626500000000000000000000000000000000000000000000000000000000000000000000000000
44459444777cc7c600d00d0000000000676067600062650000626500000000000000000000000000000000000000000000000000000000000000000000000000
444444447c76cccc000dd00000000000576d576d006d650000888500000000000000000000000000000000000000000000000000000000000000000000000000
44444444777ccccc00d00d0005666650555d555d0066650000666500000000000000000000000000000000000000000000000000000000000000000000000000
0000000088008088888ee88888eee8880000e00000eeee000eeeeee0000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000082200000888822000ee00000e000e000000e00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000002820000e0e00000e000e00000e000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000e000000000e00eeeee00000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd0000000000000000000000000000e00000eeeee0000000e0000000000000000000000000000000000000000000000000000000000000000000000000
666666660000000000000000000000000000e00000e00000000000e0000000000000000000000000000000000000000000000000000000000000000000000000
666666660000000000000000000000000000e00000e00000000000e0000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd00000000000000000000000000eeeee000eeeee00eeeee00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005500000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050050000000000005005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000d5d0500000000000d5505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000999050000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000007970d0000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777760000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777760000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777760000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777760000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777767000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777767000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777767700000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777776d57000000000000d5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777776d55570000000000d55550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd76700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd757570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07757570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
44433544444335444443354444433544444335444443354444433544444335444443354444433544444335444443354444433544444335444443354444433544
94445544944455449444554494445544944455449444554494445544944455449444554494445544944455449444554494445544944455449444554494445544
44444449444444494444444944444449444444494444444944444449444444494444444944444449444444494444444944444449444444494444444944444449
44594444445944444459444444594444445944444459444444594444445944444459444444594444445944444459444444594444445944444459444444594444
44459444444594444445944444459444444594444445944444459444444594444445944444459444444594444445944444459444444594444445944444459444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
00000000000000000000000000000000000000000000000000000000000000006600666000006660066000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000606000006060006000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000606000006060006000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000606006006060006000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006600666060006660066000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000420000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414100000040404000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000404141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000414040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000004141414040400000000000000000000000000000000000000000626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0042000000000000000000004100000000000000000000000000000000000000557300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040000000400001000000004100000000000062630000000000000000000000004040005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000400040404000004100400000000055730000000000000000000000000000004600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000404000400000000000004100000005005455400000000000000062630000000041414141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000404200000000004100000001004646404200000000000054730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444444404044414141444044444040404040404040404444404040404040404040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
