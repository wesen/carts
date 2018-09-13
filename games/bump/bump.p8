pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
flg_solid=0
flg_ice=1

--first value is default
cols_face={ 7, 12, 2, 11 }
cols_hair={ 13, 10, 8, 12 }

p1_input=0
p2_input=1
p3_input=2
p4_input=3

btn_right=1
btn_up=2
btn_down=3
btn_left=0
btn_jump=4

-- physics tweaking
local maxrun=1
local maxfall=2
local gravity=0.12
local in_air_accel=0.1
local in_air_decel=0.05
local apex_speed=0.15
local fall_gravity_factor=2
local apex_gravity_factor=0.5
local wall_slide_maxfall=0.4
local ice_wall_maxfall=1
local jump_spd=1.2
local wall_jump_spd=maxrun+0.6
local spring_speed=3
local jump_button_grace_interval=5
local jump_max_hold_time=15
local ground_grace_interval=6


frame=0
dt=0
lasttime=time()
room=nil
spawn_idx=1

actors={}
tiles={}
crs={}
scores={0, 0, 0, 0}

jump_button_grace_interval=10
jump_max_hold_time=15

ground_grace_interval=12



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

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
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


-- queues - *sigh*
function insert(t,val)
 for i=(#t+1),2,-1 do
  t[i]=t[i-1]
 end
 t[1]=val
end

function popend(t)
 local top=t[#t]
 del(t,top)
 return top
end

function reverse(t)
 for i=1,(#t/2) do
  local tmp=t[i]
  local oi=#t-(i-1)
  t[i]=t[oi]
  t[oi]=tmp
 end
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


crs={}
draw_crs={}

function tick_crs(_crs)
 _crs=_crs or crs
 for cr in all(_crs) do
  if costatus(cr)!='dead' then
   coresume(cr)
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


dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,13}

function darken(p,_pal)
 for j=1,15 do
  local kmax=(p+(j*1.46))/22
  local col=j
  for k=1,kmax do
   if (col==0) break
   col=dpal[col]
  end
  if (col==14) col=13
  if (col==2) col=5
  if (col==8) col=5
  pal(j,col,_pal)
 end
end


actor_cnt=0

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

   local solid=self:is_solid_at(v2(step,0))
   local actor=self:is_actor_at(v2(step,0))
   if solid or actor then
    self.spd.x=0
    break
   else
    self.pos.x+=step
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

   local solid=self:is_solid_at(v2(0,step))
   local actor=self:is_actor_at(v2(0,step))

   if solid or actor then
    self.spd.y=0
    break
   else
    self.pos.y+=step
   end

  end
 else
  self.pos.y+=amount
 end
end

function cls_actor:is_solid_at(offset)
 return solid_at(self:bbox(offset))
end

function cls_actor:is_actor_at(offset)
 for actor in all(actors) do
  if actor.is_solid then
   local bbox_other = actor:bbox()
   if self!=actor and bbox_other:collide(self:bbox(offset)) then
    return true
   end
  end
 end

 return false
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


local camera_shake=v2(0,0)

function add_shake(p)
 camera_shake+=angle2vec(rnd(1))*p
end

function update_shake()
 if abs(camera_shake.x)+abs(camera_shake.y)<1 then
  camera_shake=v2(0,0)
 end
 if frame%4==0 then
  camera_shake*=v2(-0.4-rnd(0.1),-0.4-rnd(0.1))
 end
end


cls_button=class(function(self,btn_nr,input_port)
 self.btn_nr=btn_nr
 self.input_port=input_port
 self.is_down=false
 self.is_pressed=false
 self.down_duration=0
 self.hold_time=0
 self.ticks_down=0
end)

function cls_button:update()
 self.is_pressed=false
 if btn(self.btn_nr, self.input_port) then
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


cls_bubble=subclass(typ_bubble,cls_actor,function(self,pos,dir)
 cls_actor._ctr(self,pos)
 self.spd=v2(-dir*rnd(0.2),-rnd(0.2))
 self.life=10
end)

function cls_bubble:draw()
 local size=4-self.life/3
 circ(self.pos.x,self.pos.y,size,1)
end

function cls_bubble:update()
 self.life*=0.9
 self:move(self.spd)
 if (self.life<0.1) then
  del(actors,self)
 end
end

function v_idx(pos)
 return pos.x+pos.y*128
end

cls_room=class(function(self,pos,dim)
 self.pos=pos
 self.dim=dim
 self.spawn_locations={}
 printh("init room")

 -- initialize tiles
 for i=0,self.dim.x-1 do
  for j=0,self.dim.y-1 do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   if tile==spr_spawn_point then
    add(self.spawn_locations,p*8)
   end
   local t=tiles[tile]
   if t!=nil then
    local a=t.init(p*8)
    a.tile=tile
   end
  end
 end
end)

function cls_room:get_friction(tile,dir)
 local accel=0.1
 local decel=0.1

 if (fget(self:tile_at(tile),flg_ice)) accel,decel=min(accel,0.1),min(decel,0.03)

 return accel,decel
end

function cls_room:draw()
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
end

function cls_room:spawn_player(input_port)
 -- XXX potentially find better spawn locatiosn
 local spawn_pos = self.spawn_locations[spawn_idx]:clone()
 local spawn=cls_spawn.init(spawn_pos, input_port)
 spawn_idx = (spawn_idx%#self.spawn_locations)+1
 return spawn
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

cls_smoke=subclass(cls_actor,function(self,pos,start_spr,dir)
 cls_actor._ctr(self,pos+v2(mrnd(1),0))
 self.flip=v2(maybe(),false)
 self.spr=start_spr
 self.start_spr=start_spr
 self.is_solid=false
 self.spd=v2(dir*(0.3+rnd(0.2)),-0.0)
 self.is_gore=false
end)

function cls_smoke:update()
 self:move(self.spd)
 self.spr+=0.2
 if (self.spr>self.start_spr+3) del(actors,self)
end

function cls_smoke:draw()
 if self.is_gore then
  pal(12,8)
  pal(7,14)
  pal(6,2)
 end
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
 if (self.is_gore) pal()
end


cls_particle=subclass(cls_actor,function(self,pos,lifetime,sprs)
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

cls_gore=subclass(cls_particle,function(self,pos)
 cls_particle._ctr(self,pos,0.5+rnd(2),{35,36,37,38,38})
 self.hitbox=hitbox(v2(2,2),v2(3,3))
 self:random_angle(1)
 self.spd.x*=0.5+rnd(0.5)
 self.weight=0.5+rnd(1)
 self:random_flip()
end)

function cls_gore:update()
 cls_particle.update(self)

 -- i tried generalizing this but it's just easier to write it out
 local dir=sign(self.spd.x)
 local ground_bbox=self:bbox(v2(0,1))
 local ceil_bbox=self:bbox(v2(0,-1))
 local side_bbox=self:bbox(v2(dir,0))
 local on_ground,ground_tile=solid_at(ground_bbox)
 local on_ceil,ceil_tile=solid_at(ceil_bbox)
 local hit_side,side_tile=solid_at(side_bbox)
 local gore_weight=1-self.t/self.lifetime
 if on_ground and ground_tile!=nil then
  self.spd.y*=-0.9
 elseif on_ceil and ceil_tile!=nil then
  self.spd.y*=-0.9
 elseif hit_side and side_tile!=nil then
  self.spd.x*=-0.9
 end
end

function make_gore_explosion(pos)
 for i=0,10 do
  cls_gore.init(pos)
 end
end


players={}

player_cnt=0

cls_player=subclass(cls_actor,function(self,pos,input_port)
 cls_actor._ctr(self,pos)
 -- players are handled separately
 add(players,self)

 self.ghosts={}

 self.nr=player_cnt
 player_cnt+=1

 self.flip=v2(false,false)
 self.input_port=input_port
 self.jump_button=cls_button.init(btn_jump, input_port)
 self.spr=1
 self.hitbox=hitbox(v2(2,0.5),v2(4,7.5))
 self.head_hitbox=hitbox(v2(0,-1),v2(8,1))
 self.feet_hitbox=hitbox(v2(2,7),v2(4,1))

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0

 self.is_teleporting=false
 self.on_ground=false
 self.is_bullet_time=false
end)

function cls_player:smoke(spr,dir)
 return cls_smoke.init(self.pos,spr,dir)
end

function cls_player:kill()
 del(players,self)
 del(actors,self)
 add_shake(3)
 sfx(1)
 if not self.is_doppelgaenger then
  room:spawn_player(self.input_port)
  for player in all(players) do
   if player.input_port==self.input_port and player.is_doppelgaenger then
    make_gore_explosion(player.pos)
    player:kill()
   end
  end
 end
end

function cls_player:update()
 if self.is_teleporting or self.is_bullet_time then
 else
  self:update_normal()
 end
end

function cls_player:update_normal()
 -- from celeste's player class
 local input=btn(btn_right, self.input_port) and 1
    or (btn(btn_left, self.input_port) and -1
    or 0)

 self.jump_button:update()

 local gravity=gravity
 local maxfall=maxfall
 local accel,decel

 local ground_bbox=self:bbox(vec_down)
 self.on_ground,tile=solid_at(ground_bbox)
 local on_actor=self:is_actor_at(v2(input,0))
 local on_ice=ice_at(ground_bbox)

 if self.on_ground then
  self.on_ground_interval=ground_grace_interval
 elseif self.on_ground_interval>0 then
  self.on_ground_interval-=1
 end
 local on_ground_recently=self.on_ground_interval>0

 if not self.on_ground then
  accel=in_air_accel
  decel=in_air_decel
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

 -- slow down at apex
 if abs(self.spd.y)<=apex_speed then
  gravity*=apex_gravity_factor
 elseif self.spd.y>0 then
  -- fall down fas2er
  gravity*=fall_gravity_factor
 end

 -- wall slide
 local is_wall_sliding=false
 if input!=0 and self:is_solid_at(v2(input,0))
    and not self.on_ground and self.spd.y>0 then
  is_wall_sliding=true
  maxfall=wall_slide_maxfall
  if (ice_at(self:bbox(v2(input,0)))) maxfall=ice_wall_maxfall
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
    sfx(0)
   end
   self.on_ground_interval=0
   self.spd.y=-jump_spd
   self.jump_button.hold_time+=1
  elseif self.jump_button:was_just_pressed() then
   -- check for wall jump
   local wall_dir=self:is_solid_at(v2(-3,0)) and -1
        or self:is_solid_at(v2(3,0)) and 1
        or 0
   if wall_dir!=0 then
    self.jump_interval=0
    self.spd.y=-1
    self.spd.x=-wall_dir*wall_jump_spd
    self:smoke(spr_wall_smoke,-wall_dir*.3)
    self.jump_button.hold_time+=1
   end
  end
 end

 if (not self.on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

 self:move(self.spd)

 -- animation
 if input==0 then
  self.spr=1
 elseif is_wall_sliding then
  self.spr=4
 elseif not self.on_ground then
  self.spr=3
 else
  self.spr=1+flr(frame/4)%3
 end

 -- interact with players
 local feet_box=self.feet_hitbox:to_bbox_at(self.pos)
 for player in all(players) do
  if self!=player then

   -- attack
   local head_box=player.head_hitbox:to_bbox_at(player.pos)
   local can_attack=not self.on_ground and self.spd.y>0
   -- printh(tostr(self.nr).." attack on ground "..tostr(on_ground))

   if (feet_box:collide(head_box) and can_attack)
    or self:bbox():collide(player:bbox()) then
    add_cr(function ()
     self.is_bullet_time=true
     player.is_bullet_time=true
     for i=0,5 do
      yield()
     end
     self.is_bullet_time=false
     player.is_bullet_time=false
     make_gore_explosion(player.pos)
     cls_smoke.init(self.pos,32,0)
     self.spd.y=-2.0
     if player.input_port==self.input_port then
      -- killed a doppelgaenger
      -- scores[self.input_port+1]-=1
     else
      scores[self.input_port+1]+=1
     end
     player:kill()
    end)
   end
  end
 end

 if (not self.on_ground and frame%2==0) insert(self.ghosts,self.pos:clone())
 if ((self.on_ground or #self.ghosts>6)) popend(self.ghosts)
end

function cls_player:draw()
 if self.is_bullet_time then
  rectfill(self.pos.x,self.pos.y,self.pos.x+8,self.pos.y+8,10)
  return
 end
 if not self.is_teleporting then
  local dark=0
  for ghost in all(self.ghosts) do
   dark+=8
   darken(dark)
   spr(self.spr,ghost.x,ghost.y,1,1,self.flip.x,self.flip.y)
  end
  pal()

  pal(cols_face[1], cols_face[self.input_port + 1])
  pal(cols_hair[1], cols_hair[self.input_port + 1])
  spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
  pal(cols_face[1], cols_face[1])
  pal(cols_hair[1], cols_hair[1])

  --[[
  local bbox=self:bbox()
  local bbox_col=8
  if self:is_solid_at(v2(0,0)) then
   bbox_col=9
  end
  bbox:draw(bbox_col)
  --bbox=self.feet_hitbox:to_bbox_at(self.pos)
  --bbox:draw(12)
  --bbox=self.head_hitbox:to_bbox_at(self.pos)
  --bbox:draw(12)
  print(self.spd:str(),64,64)
  --]]
 end
end


spr_spring_sprung=66
spr_spring_wound=67

cls_spring=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox=hitbox(v2(0,5),v2(8,3))
 self.sprung_time=0
 self.is_solid=false
end)
tiles[spr_spring_sprung]=cls_spring

function cls_spring:update()
 -- collide with players
 local bbox=self:bbox()
 if self.sprung_time>0 then
  self.sprung_time-=1
 else
  for player in all(players) do
   if bbox:collide(player:bbox()) then
    player.spd.y=-spring_speed
    self.sprung_time=10
    local smoke=cls_smoke.init(self.pos,spr_full_smoke,0)
   end
  end
 end
end

function cls_spring:draw()
 -- self:bbox():draw(9)
 local spr_=spr_spring_wound
 if (self.sprung_time>0) spr_=spr_spring_sprung
 spr(spr_,self.pos.x,self.pos.y)
end


spr_spawn_point=1

cls_spawn=subclass(cls_actor,function(self,pos,input_port)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.target=self.pos
 self.input_port=input_port
 self.pos=v2(self.target.x,128)
 self.spd.y=-2
 self.is_doppelgaenger=false
 add_cr(function()
  self:cr_spawn()
 end)
end)

function cls_spawn:cr_spawn()
 cr_move_to(self,self.target,1,inexpo)
 del(actors,self)
 local player=cls_player.init(self.target, self.input_port)
 player.is_doppelgaenger=self.is_doppelgaenger
 cls_smoke.init(self.pos,spr_full_smoke,0)
end

function cls_spawn:draw()
 spr(spr_spawn_point,self.pos.x,self.pos.y)
end


spr_spikes=68

cls_spikes=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox=hitbox(v2(0,3),v2(8,5))
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:update()
 local bbox=self:bbox()
 for player in all(players) do
  if bbox:collide(player:bbox()) then
   player:kill()
   cls_smoke.init(self.pos,32,0)
  end
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.pos.x,self.pos.y)
end


cls_moving_platform=subclass(cls_actor,function(pos)
 cls_actor._ctr(self,pos)
end)


spr_tele_enter=112
spr_tele_exit=113
tele_exits={}

cls_tele_enter=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.hitbox=hitbox(v2(4,4),v2(1,1))
end)
tiles[spr_tele_enter]=cls_tele_enter

function cls_tele_enter:update()
 local bbox=self:bbox()
 for player in all(players) do
  if bbox:collide(player:bbox()) and player.on_ground and not player.is_teleporting then
   add_cr(function()
    player.is_teleporting=true
    player.spd=v2(0,0)
    player.ghosts={}

    local anim_length=10
    for i=0,anim_length do
     local w=i/anim_length*10
     rectfill(player.pos.x+4-w,player.pos.y+4-w,player.pos.x+4+w,player.pos.y+4+w,7)
     yield()
    end
    player.pos = rnd_elt(tele_exits).pos:clone()
    for i=0,anim_length do
     local w=(anim_length-i)/anim_length*10
     rectfill(player.pos.x+4-w,player.pos.y+4-w,player.pos.x+4+w,player.pos.y+4+w,7)
     yield()
    end
    player.is_teleporting=false
   end,draw_crs)
  end
 end
end

function cls_tele_enter:draw()
 spr(spr_tele_enter,self.pos.x,self.pos.y)
end


cls_tele_exit=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 add(tele_exits, self)
end)
tiles[spr_tele_exit]=cls_tele_exit

function cls_tele_exit:draw()
 spr(spr_tele_exit,self.pos.x,self.pos.y)
end


spr_power_up=39
pwrup_drop_interval=60*10


cls_pwrup_dropper=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.time=0
 self.item=nil
end)

function cls_pwrup_dropper:update()
 if self.item==nil then

  -- Increment time. Spawn when time's up
  self.time=(self.time%(pwrup_drop_interval))+1
  if self.time==pwrup_drop_interval then
   self.item=rnd_elt(pwrups).init(self.pos)
  end

 else

  -- Check that item has been used before allowing another drop
  local exists=false
  for actor in all(actors) do
   if actor==self.item then
    exists=true
   end
  end

  if not exists then
   self.item=nil
  end

 end
end


cls_pwrup=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
end)

function cls_pwrup:update()
 local bb=self:bbox()
 for player in all(players) do
  if player:bbox():collide(bb) then
   self:act_on_player(player)
   del(actors,self)
   return
  end
 end
end

function cls_pwrup:act_on_player(player)
end

function cls_pwrup:draw()
 spr(self.tile,self.pos.x,self.pos.y)
end

cls_pwrup_doppelgaenger=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)

function cls_pwrup_doppelgaenger:act_on_player(player)
 for i=0,3 do
  local spawn=room:spawn_player(player.input_port)
  spawn.is_doppelgaenger=true
 end
end


pwrups={ cls_pwrup_doppelgaenger }
tiles[spr_power_up]=cls_pwrup_dropper


--#include constants
--#include globals
--#include config

--#include oo
--#include v2
--#include bbox
--#include hitbox
--#include camera

--#include helpers
--#include tween
--#include coroutines
--#include queues
--#include gfx

--#include actors
--#include button
--#include room
--#include smoke
--#include particle
--#include player
--#include spring
--#include spawn
--#include spikes
--#include moving_platform
--#include teleporter
--#include power-ups

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
-- x add gore particles and gored up tiles
-- x add gore on vertical surfaces
-- x make gore slippery
-- x add gore when dying
-- moving platforms
-- laser beam
-- add water
-- add butterflies
-- add flies
-- vanishing platforms
-- lookup / lookdown sprites
-- go through right and come back left (?)
-- x add second player
-- add trailing smoke particles when springing up
-- x add multiple players / spawn points
-- x add death mechanics
-- x add score
-- x camera shake
-- x doppelgangers
-- x remove typ code
-- bullet time on kill
-- decrease score when dying on spikes

-- fades

-- number of player selector menu
-- title screen
-- game end screen (kills or timer)
-- prettier score display
-- pretty pass

-- powerups - item dropper
-- visualize power ups
-- different sprites for different players
-- bomb
-- superspeed
-- invincibility
-- superjump
-- gravity tweak
-- double jump
-- dash
-- invisibility
-- meteors
-- flamethrower
-- bullet time
-- whip
-- jetpack
-- moving platforms
-- vanishing platforms
-- miniature mode
-- lasers
-- gun
-- rope
-- selfbomber (on a timer)
-- level design

-- x multiple players
-- x random player spawns
-- x player collision
-- x player kill
-- x player colors

--#include main


function _init()
 room=cls_room.init(v2(16,0),v2(16,16))
 room:spawn_player(p1_input)
 room:spawn_player(p2_input)
 room:spawn_player(p3_input)
 room:spawn_player(p4_input)
end

function _draw()
 frame+=1

 cls()
 camera(camera_shake.x,camera_shake.y)
 room:draw()
 draw_actors()
 tick_crs(draw_crs)

 local entry_length=50
 for i=0,#scores-1,1 do
  print(
   "player "..tostr(i+1)..": "..tostr(scores[i+1]),
   i*entry_length,1,7
  )
 end

 print(tostr(stat(1)),0,120,1)
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs()
 update_actors()
 update_shake()
end


__gfx__
0000000000ddd0000000000000ddd00000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000dd7670000ddd0000dd767000dd767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700dd7575700dd76700dd757570dd7575700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007757570dd75757007757570077575700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007777000775757000777700007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000990000077770000044000000999600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400000600600000446000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000008000880084080000088000008000000000000000000000000000eeeeee00000000000000000000000000000000000000000000000000000000000000000
0008480008400080000000000008e8000008e00000000000000000000eeeeee00000000000000000000000000000000000000000000000000000000000000000
008888800d0000d00000000000888880008e8800000e0000000000000eeeeee00000000000000000000000000000000000000000000000000000000000000000
004884800000000000000000002882800008820000888000000000000eeeeee00000000000000000000000000000000000000000000000000000000000000000
000444000880000800000000000222000000200000020000000e00000eeeeee00000000000000000000000000000000000000000000000000000000000000000
000000000d800d8080000008000000000000000000000000000000000eeeeee00000000000000000000000000000000000000000000000000000000000000000
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
9444554477c67c760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444449ccc677760000000000000000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44594444ccc6cccc0566665000000000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44459444777cc7c600d00d0000000000676067600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444447c76cccc000dd00000000000576d576d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444777ccccc00d00d0005666650555d555d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088008088888ee88888eee888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000082200000888822000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000028200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666660066666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000006600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000006600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000006600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60011006600ee0060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6011110660eeee060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011111100eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001030000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6060606060606060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000818181810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000420000000000700000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414100000040404000004000000000010000000000000000000000000071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000005000000004000000040402700000000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000404141000000000000010000404000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000414040404000000000420001704200400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000004040000000000000000000000000000000404141414100404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000004141414040400000000040000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0042000000000000000000004100000040404000000000000042000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040000000400001000100004100000000000000000000000140404000000040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000400040404000004100404000000000000040404040000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000404000400000000000004105000000000000000000000000000000000000000041414141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000404200000000004100050005700100004200000071000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444444404044414141444044444041414141414141414140404040404040404040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001a050180501a0500000012050120501105000000100501005010050100501005012050130501605000000190501a0501d0501e0502005023050270500000000000000000000000000000000000000000
0003000000000142101325012250112500f2500c250092500a2400724005240032400121001210052000420001200032000320016200162001620016200162001b2001d2001f2002b20030200352003520000000