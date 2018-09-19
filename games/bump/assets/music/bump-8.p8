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
btn_action=5

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
particles={}
interactables={}
environments={}
static_objects={}
tiles={}
crs={}
scores={0, 0, 0, 0}

jump_button_grace_interval=6
jump_max_hold_time=15

ground_grace_interval=6


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

local bboxvt={}
bboxvt.__index=bboxvt

function hitbox_to_bbox(hb,off)
 local lx=hb.x+off.x
 local ly=hb.y+off.y

 return bbox(v2(lx,ly),v2(lx+hb.dimx,ly+hb.dimy))
end

function bbox(aa,bb)
 return setmetatable({aax=aa.x,aay=aa.y,bbx=bb.x,bby=bb.y},bboxvt)
end

function bboxvt:w()
 return self.bbx-self.aax
end

function bboxvt:h()
 return self.bby-self.aay
end

function bboxvt:is_inside(v)
 return v.x>=self.aax
 and v.x<=self.bbx
 and v.y>=self.aay
 and v.y<=self.bby
end

function bboxvt:str()
 return tostr(self.aax)..","..tostr(self.aay).."-"..tostr(self.bbx)..","..tostr(self.bby)
end

function bboxvt:draw(col)
 rect(self.aax,self.aay,self.bbx-1,self.bby-1,col)
end

function bboxvt:to_tile_bbox()
 local x0=max(0,flr(self.aax/8))
 local x1=min(room.dim_x,(self.bbx-1)/8)
 local y0=max(0,flr(self.aay/8))
 local y1=min(room.dim_y,(self.bby-1)/8)
 return bbox(v2(x0,y0),v2(x1,y1))
end

function bboxvt:collide(other)
 return other.bbx > self.aax and
   other.bby > self.aay and
   other.aax < self.bbx and
   other.aay < self.bby
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

function cr_move_to(obj,target_x,target_y,d,easetype)
 local t=0
 local bx=obj.x
 local cx=target_x-obj.x
 local by=obj.y
 local cy=target_y-obj.y
 while t<d do
  t+=dt
  if (t>d) return
  obj.x=round(easetype(t,bx,cx,d))
  obj.y=round(easetype(t,by,cy,d))
  yield()
 end
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


cls_interactable=class(function(self,x,y,hitbox_x,hitbox_y,hitbox_dim_x,hitbox_dim_y)
 add(interactables,self)
 self.x=x
 self.y=y
 self.aax=self.x+hitbox_x
 self.aay=self.y+hitbox_y
 self.bbx=self.aax+hitbox_dim_x
 self.bby=self.aay+hitbox_dim_y
end)

function cls_interactable:update()
end

function cls_interactable:draw()
 spr(self.spr,self.x,self.y)
end


cls_actor=class(function(self,pos)
 self.x=pos.x
 self.y=pos.y
 self.spd_x=0
 self.spd_y=0
 self.is_solid=true
 if (self.hitbox==nil) self.hitbox={x=0.5,y=0.5,dimx=7,dimy=7}
 self:update_bbox()
 add(actors,self)
end)

function cls_actor:update_bbox()
 self.aax=self.hitbox.x+self.x
 self.aay=self.hitbox.y+self.y
 self.bbx=self.aax+self.hitbox.dimx
 self.bby=self.aay+self.hitbox.dimy
end

function cls_actor:bbox(x,y)
 x=x or 0
 y=y or 0
 return setmetatable({aax=self.aax+x,aay=self.aay+y,bbx=self.bbx+x,bby=self.bby+y},bboxvt)
 -- return setmetatable({
 --    aax=self.x+self.hitbox.x+x,
 --    aay=self.y+self.hitbox.y+y,
 --    bbx=self.x+self.hitbox.x+self.hitbox.dimx+x,
 --    bby=self.y+self.hitbox.y+self.hitbox.dimy+y},
  -- bboxvt)
end

function cls_actor:str()
 return "actor["..tostr(self.id)..",t:"..tostr(self.typ).."]"
end

function cls_actor:move_x(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)

   local solid=solid_at_offset(self,step,0)
   local actor=self:is_actor_at(step,0)

   printh("self.x "..tostr(self.x).." amount "..tostr(amount).." solid "..tostr(solid).." actor "..tostr(actor))

   if solid or actor then
    if abs(step)<0.1 then
     self.spd_x=0
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

   printh(tostr(self.name).." pos "..tostr(self.x)..","..tostr(self.y).." amount "..tostr(amount).." solid "..tostr(solid).." actor "..tostr(actor))

   if solid or actor then
    if abs(step)<0.1 then
     self.spd_y=0
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
 for actor in all(actors) do
  if (actor.is_solid and self!=actor and do_bboxes_collide_offset(self,actor,x,y)) return true,actor
 end

 return false,nil
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

function v_idx(pos)
 return pos.x+pos.y*128
end

cls_room=class(function(self,pos,dim)
 self.x=pos.x
 self.y=pos.y
 self.dim_x=dim.x
 self.dim_y=dim.y
 self.spawn_locations={}
 self.aax=0
 self.aay=0
 self.bbx=self.dim_x*8
 self.bby=self.dim_y*8

 -- initialize tiles
 for i=0,self.dim_x-1 do
  for j=0,self.dim_y-1 do
   local tile=mget(self.x+i,self.y+j)
   local p={x=i*8,y=j*8}
   if tile==spr_spawn_point then
    add(self.spawn_locations,p)
   end
   local t=tiles[tile]
   if t!=nil then
    local a=t.init(p)
    a.tile=tile
   end
  end
 end
end)

function cls_room:draw()
 map(self.x,self.y,0,0,self.dim_x,self.dim_y,flg_solid+1+16)
end

function cls_room:spawn_player(input_port)
 -- xxx potentially find better spawn locatiosn
 local spawn_pos = self.spawn_locations[spawn_idx]
 local spawn=cls_spawn.init(spawn_pos, input_port)
 spawn_idx = (spawn_idx%#self.spawn_locations)+1
 connected_players[input_port]=true
 return spawn
end

function solid_at_offset(bbox,x,y)
 if bbox.aax+x<0
  or bbox.bbx+x>room.bbx
  or bbox.aay+y<0
  or bbox.bby+y>room.bby then
   return true,nil
 end
 if (tile_flag_at_offset(bbox,flg_solid,x,y)) return true,nil
 for e in all(environments) do
  if (e:collides_with(bbox,x,y)) return true,e
 end
 return false,nil
end

function ice_at_offset(bbox,x,y)
 return tile_flag_at_offset(bbox,flg_ice,x,y)
end

function tile_flag_at_offset(bbox,flag,x,y)
 local aax=max(0,flr((bbox.aax+x)/8))+room.x
 local aay=max(0,flr((bbox.aay+y)/8))+room.y
 local bbx=min(room.dim_x,(bbox.bbx+x-1)/8)+room.x
 local bby=min(room.dim_y,(bbox.bby+y-1)/8)+room.y
 for i=aax,bbx do
  for j=aay,bby do
   if fget(mget(i,j),flag) then
    return true
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

cls_smoke=class(function(self,pos,start_spr,dir)
 self.x=pos.x+mrnd(1)
 self.y=pos.y
 add(particles,self)
 self.flip_x=maybe()
 self.spr=start_spr
 self.start_spr=start_spr
 self.spd_x=dir*(0.3+rnd(0.2))
end)

function cls_smoke:update()
 self.x+=self.spd_x
 self.spr+=0.2
 if (self.spr>self.start_spr+3) del(particles,self)
end

function cls_smoke:draw()
 spr(self.spr,self.x,self.y,1,1,self.flip_x,false)
end

cls_particle=class(function(self,pos,lifetime,sprs)
 self.x=pos.x+mrnd(1)
 self.y=pos.y
 add(particles,self)
 self.flip=v2(false,false)
 self.t=0
 self.lifetime=lifetime
 self.sprs=sprs
 self.weight=0
end)

function cls_particle:random_flip()
 self.flip=v2(maybe(),maybe())
end

function cls_particle:random_angle(spd)
 local v=angle2vec(rnd(1))
 self.spd_x=v.x*spd
 self.spd_y=v.y*spd
end

function cls_particle:update()
 self.aax=self.x+2
 self.bbx=self.x+4
 self.aay=self.y+2
 self.bby=self.y+4
 self.t+=dt

 if self.t>self.lifetime then
   del(particles,self)
   return
 end

 self.x+=self.spd_x
 self.aax+=self.spd_x
 self.bbx+=self.spd_x
 self.y+=self.spd_y
 self.aay+=self.spd_y
 self.bby+=self.spd_y
 self.spd_y=appr(self.spd_y,2,0.12)
end

function cls_particle:draw()
 local idx=flr(#self.sprs*(self.t/self.lifetime))
 local spr_=self.sprs[1+idx]
 spr(spr_,self.x,self.y,1,1)
end

cls_gore=subclass(cls_particle,function(self,pos)
 cls_particle._ctr(self,pos,0.5+rnd(2),{35,36,37,38,38})
 self.hitbox={x=2,y=2,dimx=3,dimy=3}
 self:random_angle(1)
 self.spd_x*=0.5+rnd(0.5)
 self.weight=0.5+rnd(1)
 -- self:random_flip()
end)

function cls_gore:update()
 cls_particle.update(self)

 -- i tried generalizing this but it's just easier to write it out
 local dir=sign(self.spd_x)
 if tile_flag_at_offset(self,flg_solid,0,1) then
  self.spd_y*=-0.9
--  elseif tile_flag_at_offset(self,flg_solid,0,-1) then
--   self.spd_y*=-0.9
elseif tile_flag_at_offset(self,flg_solid,dir,0) then
  self.spd_x*=-0.9
 end
end

function make_gore_explosion(pos)
 for i=0,10 do
  cls_gore.init(pos)
 end
end

players={}
connected_players={}
player_cnt=0

function check_for_new_players()
 for i=0,3 do
  if (btnp(btn_jump,i) or btnp(btn_action,i)) and connected_players[i]==nil then
   room:spawn_player(i)
  end
 end
end

cls_player=subclass(cls_actor,function(self,pos,input_port)
 self.hitbox={x=2,y=0.5,dimx=4,dimy=7.5}
 cls_actor._ctr(self,pos)
 -- players are handled separately
 add(players,self)

 self.name="player:"..tostr(input_port)..":"..tostr(player_cnt)

 self.ghosts={}

 self.nr=player_cnt
 self.power_up=nil
 self.power_up_countdown=nil
 player_cnt+=1

 self.flip=v2(false,false)
 self.input_port=input_port
 self.jump_button=cls_button.init(btn_jump, input_port)
 self.spr=1

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0

 self.is_teleporting=false
 self.on_ground=false
 self.is_bullet_time=false
 self.is_dead=false
end)

function cls_player:update_bbox()
 if self.power_up_type!=spr_pwrup_shrink then
  cls_actor.update_bbox(self)
  self.head_box={
    aax=self.x+0,
    aay=self.y-1
   }
  self.head_box.bbx=self.head_box.aax+8
  self.head_box.bby=self.head_box.aay+1

  self.feet_box={
    aax=self.x+2,
    aay=self.y+7
   }
  self.feet_box.bbx=self.feet_box.aax+4
  self.feet_box.bby=self.feet_box.aay+1
 else
  self.aax=self.x+3
  self.aay=self.y+4.5
  self.bbx=self.aax+3
  self.bby=self.aay+3.5

  self.head_box={
    aax=self.x+2,
    aay=self.y+5
   }
  self.head_box.bbx=self.head_box.aax+4
  self.head_box.bby=self.head_box.aay+1

  self.feet_box={
    aax=self.x+2,
    aay=self.y+7
   }
  self.feet_box.bbx=self.feet_box.aax+4
  self.feet_box.bby=self.feet_box.aay+1
 end
end

function cls_player:smoke(spr,dir)
 return cls_smoke.init(v2(self.x,self.y),spr,dir)
end

function cls_player:kill()
 if not self.is_dead then
  del(players,self)
  del(actors,self)
  self.is_dead=true
  add_shake(3)
  sfx(1)
  if not self.is_doppelgaenger then
   room:spawn_player(self.input_port)
   for player in all(players) do
    if player.input_port==self.input_port and player.is_doppelgaenger then
     make_gore_explosion(v2(player.x,player.y))
     player:kill()
    end
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
 -- power up countdown
 if self.power_up_countdown!=nil then
  self.power_up_countdown-=dt
  if self.power_up_countdown<0 then
   self:clear_power_up()
  end
 end

 -- from celeste's player class
 local input=btn(btn_right, self.input_port) and 1
    or (btn(btn_left, self.input_port) and -1
    or 0)

 self.jump_button:update()

 local gravity=gravity
 local maxfall=maxfall
 local maxrun=maxrun
 local accel=0.1
 local decel=0.1
 local jump_spd=jump_spd

 if self.power_up_type==spr_pwrup_superspeed then
  maxrun*=1.5
  decel*=2
  accel*=2
 elseif self.power_up_type==spr_pwrup_superjump then
  jump_spd*=1.5
 elseif self.power_up_type==spr_pwrup_gravitytweak then
  gravity*=0.7
  maxfall*=0.5
 end

 self.on_ground=solid_at_offset(self,0,1)
 local on_ice=ice_at_offset(self,0,1)

 if self.on_ground then
  self.on_ground_interval=ground_grace_interval
 elseif self.on_ground_interval>0 then
  self.on_ground_interval-=1
 end
 local on_ground_recently=self.on_ground_interval>0

   local solid=solid_at_offset(self,0,0)
   local actor,a=self:is_actor_at(0,0)

   if solid then
   printh("foobar "..tostr(self.name).." pos "..tostr(self.x)..","..tostr(self.y).." amount "..tostr(amount).." solid "..tostr(solid).." actor "..tostr(actor))
    foobar="a"..nil
   end

 if not self.on_ground then
  accel=in_air_accel
  decel=in_air_decel
 else
  if on_ice then
   accel=0.1
   decel=0.03
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
  if input==0 and abs(self.spd_x)>0.3
     and (maybe(0.15) or self.prev_input!=0) then
   if on_ice then
    self:smoke(spr_slide_smoke,-input)
   end
  end
 end
 self.prev_input=input

 -- x movement
 if abs(self.spd_x)>maxrun then
  self.spd_x=appr(self.spd_x,sign(self.spd_x)*maxrun,decel)
 elseif input != 0 then
  self.spd_x=appr(self.spd_x,input*maxrun,accel)
 else
  self.spd_x=appr(self.spd_x,0,decel)
 end
 if (self.spd_x!=0) self.flip.x=self.spd_x<0

 -- y movement

 -- slow down at apex
 if abs(self.spd_y)<=apex_speed then
  gravity*=apex_gravity_factor
 elseif self.spd_y>0 then
  -- fall down fas2er
  gravity*=fall_gravity_factor
 end

 -- wall slide
 local is_wall_sliding=false
 if input!=0 and solid_at_offset(self,input,0)
    and not self.on_ground and self.spd_y>0 then
  is_wall_sliding=true
  maxfall=wall_slide_maxfall
  if (ice_at_offset(self,input,0)) maxfall=ice_wall_maxfall
  local smoke_dir = self.flip.x and .3 or -.3
  if maybe(.1) then
    local smoke=self:smoke(spr_wall_smoke,smoke_dir)
    smoke.flip_x=self.flip.x
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
   self.spd_y=-jump_spd
   self.jump_button.hold_time+=1
  elseif self.jump_button:was_just_pressed() then
   -- check for wall jump
   local wall_dir=solid_at_offset(self,-3,0) and -1
        or solid_at_offset(self,3,0) and 1
        or 0
   if wall_dir!=0 then
    self.jump_interval=0
    self.spd_y=-1
    self.spd_x=-wall_dir*wall_jump_spd
    self:smoke(spr_wall_smoke,-wall_dir*.3)
    self.jump_button.hold_time+=1
   end
  end
 end

 if (not self.on_ground) self.spd_y=appr(self.spd_y,maxfall,gravity)

 self:move_x(self.spd_x)
 self:move_y(self.spd_y)

 -- avoid ceiling sliding
 if self.spd_y==0 then
  self.jump_button.hold_time=0
 end

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

 if (self.power_up_type==spr_pwrup_shrink) self.spr+=4

 -- interact with players
 for player in all(players) do
  if self!=player and player.power_up_type!=spr_pwrup_invincibility then
   local kill_player=false

   if self.power_up_type==spr_pwrup_invincibility
    and do_bboxes_collide_offset(self,player,input,0) then
    kill_player=true
   else
    -- attack
    local can_attack=not self.on_ground and self.spd_y>0

    if (do_bboxes_collide(self.feet_box,player.head_box) and can_attack)
       or do_bboxes_collide(self,player) then
     self.spd_y=-2.0
     kill_player=true
    end
   end

   if kill_player then
    add_cr(function ()
     self.is_bullet_time=true
     player.is_bullet_time=true
     for i=0,3 do
      yield()
     end
     self.is_bullet_time=false
     player.is_bullet_time=false
     make_gore_explosion(v2(player.x,player.y))
     cls_smoke.init(v2(self.x,self.y),32,0)
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

 for a in all(interactables) do
  if (do_bboxes_collide(self,a)) a:on_player_collision(self)
 end


if (not self.on_ground and frame%2==0) insert(self.ghosts,{x=self.x,y=self.y})
if ((self.on_ground or #self.ghosts>6)) popend(self.ghosts)
end

function cls_player:clear_power_up()
 if self.power_up!=nil then
  self.power_up:on_powerup_stop(self)
  self.power_up=nil
  self.power_up_type=nil
  self.power_up_countdown=nil
 end
end

function cls_player:draw()
 if self.is_bullet_time then
  rectfill(self.x,self.y,self.x+8,self.y+8,10)
  return
 end
 if not self.is_teleporting then
  if (self.power_up_type==spr_pwrup_invisibility and frame%60<50) return
  local dark=0
  for ghost in all(self.ghosts) do
   dark+=8
   darken(dark)
   spr(self.spr,ghost.x,ghost.y,1,1,self.flip.x,self.flip.y)
  end
  pal()

  pal(cols_face[1], cols_face[self.input_port + 1])
  pal(cols_hair[1], cols_hair[self.input_port + 1])
  if powerup_colors[self.power_up_type]!=nil then
   bspr(self.spr,self.x,self.y,self.flip.x,self.flip.y,powerup_colors[self.power_up_type])
  else
   spr(self.spr,self.x,self.y,1,1,self.flip.x,self.flip.y)
  end
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

cls_spring=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,5,8,3)
 self.sprung_time=0
end)
tiles[spr_spring_sprung]=cls_spring

function cls_spring:update()
 -- collide with players
 if (self.sprung_time>0) self.sprung_time-=1
end

function cls_spring:on_player_collision(player)
 player.spd_y=-spring_speed
 self.sprung_time=10
 local smoke=cls_smoke.init(v2(self.x,self.y),spr_full_smoke,0)
end

function cls_spring:draw()
 -- self:bbox():draw(9)
 local spr_=spr_spring_wound
 if (self.sprung_time>0) spr_=spr_spring_sprung
 spr(spr_,self.x,self.y)
end

spr_spawn_point=1

cls_spawn=class(function(self,pos,input_port)
 add(particles,self)
 self.x=pos.x
 self.y=128
 self.is_solid=false
 self.target_x=pos.x
 self.target_y=pos.y
 self.input_port=input_port
 self.is_doppelgaenger=false
 add_cr(function()
  self:cr_spawn()
 end)
end)

function cls_spawn:update()
end

function cls_spawn:cr_spawn()
 cr_move_to(self,self.target_x,self.target_y,1,inexpo)
 del(particles,self)
 local player=cls_player.init(v2(self.target_x,self.target_y), self.input_port)
 player.is_doppelgaenger=self.is_doppelgaenger
 cls_smoke.init(v2(self.x,self.y),spr_full_smoke,0)
end

function cls_spawn:draw()
 spr(spr_spawn_point,self.x,self.y)
end

spr_spikes=68

cls_spikes=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,3,8,5)
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:on_player_collision(player)
 if player.power_up!=spr_pwrup_invincibility then
  player:kill()
  make_gore_explosion(v2(player.x,player.y))
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.x,self.y)
end

cls_moving_platform=subclass(cls_actor,function(pos)
 cls_actor._ctr(self,pos)
end)

spr_tele_enter=112
spr_tele_exit=113
tele_exits={}

cls_tele_enter=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,4,4,1,1)
end)
tiles[spr_tele_enter]=cls_tele_enter

function cls_tele_enter:on_player_collision(player)
 if player.on_ground and not player.is_teleporting then
  add_cr(function()
   player.is_teleporting=true
   player.spd=v2(0,0)
   player.ghosts={}

   local anim_length=10
   for i=0,anim_length do
    local w=i/anim_length*10
    rectfill(player.x+4-w,player.y+4-w,player.x+4+w,player.y+4+w,7)
    yield()
   end
   local exit=rnd_elt(tele_exits)
   player.x,player.y=exit.x,exit.y
   for i=0,anim_length do
    local w=(anim_length-i)/anim_length*10
    rectfill(player.x+4-w,player.y+4-w,player.x+4+w,player.y+4+w,7)
    yield()
   end
   player.is_teleporting=false
  end,draw_crs)
 end
end

function cls_tele_enter:draw()
 spr(spr_tele_enter,self.x,self.y)
end


cls_tele_exit=class(function(self,pos)
 self.x=pos.x
 self.y=pos.y
 add(tele_exits,self)
 add(static_objects,self)
end)
tiles[spr_tele_exit]=cls_tele_exit

function cls_tele_exit:update()
end

function cls_tele_exit:draw()
 spr(spr_tele_exit,self.x,self.y)
end

drop_min_time=60*4
drop_max_time=60*10

max_count=2

power_up_droppers={}

cls_pwrup_dropper=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 -- set spawn time between min time and max time
 self.time=0
 self.item=nil
 self.interval=1
 add(power_up_droppers,self)
end)

local pwrup_counts=0

function cls_pwrup_dropper:update()
 if self.item==nil then
  -- increment time. spawn when time's up
  self.time=(self.time%(self.interval))+1
  if self.time>=self.interval then
   printh("dropper time interval "..tostr(self.time).." "..tostr(self.interval))
   if pwrup_counts<max_count then
    local spr_idx=power_up_tiles[flr(rnd(#power_up_tiles))+1]
    printh("load spr "..tostr(spr_idx).." "..tostr(pwrup_counts))
    self.item=tiles[spr_idx].init(v2(self.x,self.y))
    self.item.tile=spr_idx
    pwrup_counts+=1
   end
   self.interval=flr(drop_min_time+(rnd(1)*(drop_max_time-drop_min_time)))
  end

 else

  -- check that item has been used before allowing another drop
  local exists=false
  for interactable in all(interactables) do
   if interactable==self.item then
    exists=true
   end
  end

  if not exists then
   printh("decreasing")
   pwrup_counts-=1
   self.item=nil
   self.interval=flr(drop_min_time+(rnd(1)*(drop_max_time-drop_min_time)))
   if pwrup_counts<max_count then
    for dropper in all(power_up_droppers) do
     dropper.time=0
    end
   end
  end
 end
end

spr_pwrup_dropper=25
tiles[spr_pwrup_dropper]=cls_pwrup_dropper


cls_pwrup=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,0,8,8)
end)

function cls_pwrup:on_player_collision(player)
 if player.power_up!=nil then
  player:clear_power_up()
 end

 self:on_powerup_start(player)
 player.power_up=self
 player.power_up_type=self.tile
 player.power_up_countdown=powerup_countdowns[self.tile]

  del(interactables,self)
end

function cls_pwrup:on_powerup_start(player)
end

function cls_pwrup:on_powerup_stop(player)
end

function cls_pwrup:draw()
 spr(self.tile,self.x,self.y)
end

cls_pwrup_doppelgaenger=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)

function cls_pwrup_doppelgaenger:on_powerup_stop(player)
 for _p in all(players) do
  if _p.input_port==player.input_port and _p.is_doppelgaenger then
   del(players,_p)
   del(actors,_p)
   make_gore_explosion(v2(_p.x,_p.y))
  end
 end
end

function cls_pwrup_doppelgaenger:on_powerup_start(player)
 for i=0,3 do
  local spawn=room:spawn_player(player.input_port)
  spawn.is_doppelgaenger=true
 end
end

powerup_colors={}
powerup_countdowns={}


spr_pwrup_doppelgaenger=39
--tiles[spr_pwrup_doppelgaenger]=cls_pwrup_doppelgaenger
powerup_colors[spr_pwrup_doppelgaenger]=8

spr_pwrup_invincibility=40
--tiles[spr_pwrup_invincibility]=cls_pwrup
powerup_colors[spr_pwrup_invincibility]=9
powerup_countdowns[spr_pwrup_invincibility]=10

spr_pwrup_superspeed=41
--tiles[spr_pwrup_superspeed]=cls_pwrup
powerup_colors[spr_pwrup_superspeed]=6
powerup_countdowns[spr_pwrup_superspeed]=10

spr_pwrup_superjump=42
--tiles[spr_pwrup_superjump]=cls_pwrup
powerup_colors[spr_pwrup_superjump]=12
powerup_countdowns[spr_pwrup_superjump]=15

spr_pwrup_gravitytweak=43
--tiles[spr_pwrup_gravitytweak]=cls_pwrup
powerup_colors[spr_pwrup_gravitytweak]=9
powerup_countdowns[spr_pwrup_gravitytweak]=30

spr_pwrup_invisibility=44
--tiles[spr_pwrup_invisibility]=cls_pwrup
powerup_countdowns[spr_pwrup_invisibility]=5

spr_pwrup_shrink=46
--tiles[spr_pwrup_shrink]=cls_pwrup
powerup_countdowns[spr_pwrup_shrink]=10

-- start offset for the item sprite values
spr_idx_start=39
-- associate sprite value with class
tiles[spr_pwrup_doppelgaenger]=cls_pwrup_doppelgaenger
tiles[spr_pwrup_invisibility]=cls_pwrup
tiles[spr_pwrup_shrink]=cls_pwrup
tiles[spr_pwrup_invincibility]=cls_pwrup
tiles[spr_pwrup_superjump]=cls_pwrup
tiles[spr_pwrup_superspeed]=cls_pwrup
tiles[spr_pwrup_gravitytweak]=cls_pwrup

power_up_tiles={
 spr_pwrup_doppelgaenger,
 -- spr_pwrup_invincibility,
 -- spr_pwrup_superjump,
 spr_pwrup_invisibility,
 spr_pwrup_invisibility,
 spr_pwrup_invisibility,
 -- spr_pwrup_superspeed,
 -- spr_pwrup_gravitytweak,
 spr_pwrup_shrink
}

spr_mine=69

cls_mine=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,6,8,2)
 self.spr=spr_mine
end)

function make_blast(x,y,radius)
 add_cr(function ()
  for i=0,20 do
   local r=outexpo(i,radius,-radius,20)
   circfill(x+4,y+6,r,7)
   yield()
  end
 end, draw_crs)
 for p in all(players) do
  if p.power_up!=spr_pwrup_invincibility then
   local dx=p.x-x
   local dy=p.y-y
   local d=sqrt(dx*dx+dy*dy)
   if d<radius then
    p:kill()
    make_gore_explosion(v2(p.x,p.y))
   end
  end
 end
end

function cls_mine:on_player_collision(player)
 make_blast(self.x,self.y,30)
 del(interactables,self)
end
tiles[spr_mine]=cls_mine

cls_suicide_bomb=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)

function cls_suicide_bomb:on_powerup_stop(player)
 if (player.power_up_countdown<=0) make_blast(player.x,player.y,30)
end

spr_suicide_bomb=45
powerup_colors[spr_suicide_bomb]=8
powerup_countdowns[spr_suicide_bomb]=5
tiles[spr_suicide_bomb]=cls_suicide_bomb

spr_balloon=24
cls_balloon_pwrup=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)
tiles[spr_balloon]=cls_balloon_pwrup

function cls_balloon_pwrup:on_powerup_start(player)
 local balloon=cls_balloon.init(player)
end

cls_balloon=subclass(cls_actor,function(self,player)
 cls_actor._ctr(self,v2(player.x,player.y))
 self.is_released=false
 self.is_solid=false
 self.player=player
 self.t=0
end)

function cls_balloon:update()
 self.t+=dt

 local solid=solid_at_offset(self,0,0)
 local is_actor,actor=self:is_actor_at(0,0)

 if solid or (is_actor and actor!=self.player) then
  self.player:clear_power_up()
  del(actors,self)
 elseif not self.is_released then
  if (self.player.is_dead) del(actors,self)
  self.x=self.player.x+sin(self.t)*3
  self.player.y=self.y+12
  if btnp(btn_action,self.player.input_port) then
   self.is_released=true
  end
 end

 self.y-=.5
end

function cls_balloon:draw()
 spr(spr_balloon,self.x,self.y)
 if not self.is_released then
  line(self.player.x+4,self.player.y,self.x+4,self.y+7,7)
 end
end

spr_vanishing_platform=96

vp_state_visible=0
vp_state_vanishing=1
vp_state_vanished=2

cls_vanishing_platform=class(function(self,pos)
 self.x=pos.x
 self.y=pos.y
 self.aax=pos.x
 self.aay=pos.y+0.5
 self.bbx=self.aax+8
 self.bby=self.aay+3.5
 self.state=vp_state_visible
 self.spr=spr_vanishing_platform
 add(environments,self)
end)
tiles[spr_vanishing_platform]=cls_vanishing_platform

function cls_vanishing_platform:collides_with(o,x,y)
 return self.state!=vp_state_vanished and do_bboxes_collide_offset(o,self,x,y)
end

function cls_vanishing_platform:draw()
 if (self.state!=vp_state_vanished) spr(self.spr,self.x,self.y)
end

function cls_vanishing_platform:update()
 if self.state==vp_state_visible then
  for p in all(players) do
   if do_bboxes_collide_offset(p,self,0,1) then
    self.state=vp_state_vanishing
    add_cr(function()
     cr_wait_for(.2)
     self.spr=spr_vanishing_platform+1
     cr_wait_for(.5)
     self.spr=spr_vanishing_platform+2
     cr_wait_for(.5)
     self.state=vp_state_vanished
     cr_wait_for(2)
     self.state=vp_state_visible
     self.spr=spr_vanishing_platform
    end)
   end
  end
 end
end

spr_bomb=23
cls_bomb_pwrup=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)
tiles[spr_bomb]=cls_bomb_pwrup

function cls_bomb_pwrup:on_powerup_start(player)
 local bomb=cls_bomb.init(player)
end

cls_bomb=subclass(cls_actor,function(self,player)
 cls_actor._ctr(self,v2(player.x,player.y))
 self.is_thrown=false
 self.is_solid=false
 self.player=player
 self.time=5
 self.name="bomb"
end)

function cls_bomb:update()
 local solid=solid_at_offset(self,0,0)
 local is_actor,actor=self:is_actor_at(0,0)

 self.time-=dt
 if self.time<0 then
  make_blast(self.x,self.y,45)
  del(actors,self)
 end

 if self.is_thrown then
  local actor,a=self:is_actor_at(0,0)
  if actor then
   make_blast(self.x,self.y,45)
   del(actors,self)
  end

  local gravity=0.12
  local maxfall=2
  self.spd_y=appr(self.spd_y,maxfall,gravity)
  cls_actor.move_x(self,self.spd_x)
  cls_actor.move_y(self,self.spd_y)
 elseif self.player.is_dead then
  del(actors,self)
 else
  self.x=self.player.x
  self.y=self.player.y-8
  if btnp(btn_action,self.player.input_port) then
   self.is_thrown=true
   self.spd_x=(self.player.flip.x and -1 or 1) + self.player.spd_x
   self.spd_y=-1
   self.is_solid=true
  end
 end
end

function cls_bomb:draw()
 spr(spr_bomb,self.x,self.y)
end

add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)


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
   size=rnd(2),
   maxlife=30+rnd(50),
   life=0,
   counter=0,
   radius=30+min(v.x,v.y)
  }
  p.life=rnd(p.maxlife)
  add(fireflies,p)
 end
end


-- x split into actors / particles / interactables
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
-- x vanishing platforms
-- x add second player
-- x add multiple players / spawn points
-- x add death mechanics
-- x add score
-- x camera shake
-- x doppelgangers
-- x remove typ code
-- x bullet time on kill

-- x invincibility
-- x blast mine
-- x superspeed
-- x superjump
-- x gravity tweak
-- x suicide bomber
-- x invisibility
-- x bomb
-- x miniature mode
-- x have players join when pressing action
-- x balloon pulling upwards

-- make player selection screen

-- moving platforms
-- laser beam
-- add water
-- add butterflies
-- add flies
-- lookup / lookdown sprites
-- add trailing smoke particles when springing up

-- fades
-- better kill animations
-- restore ghosts / particles on player
-- decrease score when dying on spikes

-- number of player selector menu
-- title screen
-- game end screen (kills or timer)
-- prettier score display
-- pretty pass

-- powerups - item dropper
-- refactor powerups to have a decent api
-- visualize power ups
-- different sprites for different players
-- double jump
-- dash
-- meteors
-- flamethrower
-- bullet time
-- whip
-- jetpack
-- lasers
-- gun
-- rope
-- level design

-- x multiple players
-- x random player spawns
-- x player collision
-- x player kill
-- x player colors

-- go through right and come back left (?)

function _init()
 room=cls_room.init(v2(0,16),v2(16,16))
 room:spawn_player(p1_input)
 room:spawn_player(p1_input)
 room:spawn_player(p1_input)
 room:spawn_player(p1_input)
 fireflies_init(v2(16,16))
 -- room:spawn_player(p2_input)
 --room:spawn_player(p3_input)
 --room:spawn_player(p4_input)
end

function _draw()
 frame+=1

 cls()
 camera(camera_shake.x,camera_shake.y)
 room:draw()
 for a in all(interactables) do
  a:draw()
 end
 for a in all(environments) do
  a:draw()
 end
 for a in all(static_objects) do
  a:draw()
 end
 draw_actors()
 tick_crs(draw_crs)
 fireflies_draw()

 for a in all(particles) do
  a:draw()
 end

 local entry_length=50
 for i=0,#scores-1,1 do
  print(
   "player "..tostr(i+1)..": "..tostr(scores[i+1]),
   i*entry_length,1,7
  )
 end

 -- print(tostr(stat(1)).." actors "..tostr(#actors),0,8,7)
 -- print(tostr(stat(1)/#particles).." particles "..tostr(#particles),0,16,7)
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 check_for_new_players()

 for a in all(actors) do
  a:update_bbox()
 end
 tick_crs()
 foreach(environments, function(a)
  a:update()
 end)
 update_actors()
 foreach(particles, function(a)
  a:update()
 end)
 foreach(interactables, function(a)
  a:update()
 end)
 update_shake()

 fireflies_update()
end


__gfx__
0000000000ddd0000000000000ddd00000ddd0000000000000000000000000000000000000000000000000111100000000000111111111111110000000000000
000000000dd7670000ddd0000dd767000dd767000000000000000000000000000000000000000000000001111110000000001111111111111111000000000000
00700700dd7575700dd76700dd757570dd7575700000000000000000000000000000000000000000000011000011000000011000000000000001100000000000
0007700007757570dd75757007757570077575700000000000000000000000000000000000000000000110011001100000110001100000011000110000000000
0007700000777700077575700077770000777700000ddd00000ddd0000dddd00000ddd0000000000001100011000110001100001100000011000011000000000
007007000009900000777700000440000009996000d171000001710000d1710000d1710000000000011000000000011011000000000000000000001100000000
00000000000440000004400000600600000446000009990000099000000999000004496000000000011111111111111011111111111111111111111100000011
00000000000660000006060000000000000000000006060000066000006000600000000000000000000000000000000000000000000000000000000000000111
000000000ff0ff0000000000f000f0000000011111111111111000000000790000288820000dd000000000001111111111111111111111110000000000000000
0990009900f00f0000f00f000fff0000000011111111111111110000000760a00288878200d00d00000000001010100100100100100101010111111111111111
0095959000ffff0000ffff000cfc00000001100000000000000110000155110008888e8e0d0000d0000000001110000000000000000001110100000000000000
0009990000fcfc00f0fcfc0066e6600000110001100000011000110016655110088888880d000d00000000001000000000000000000000010100000000000000
0009e900f0ffffe0f0fffef00f6f00f0011000011000000110000110566555100288888200d0d000000000001110000000000000000001110100000000000000
00000009f0099000f0044f000fff00f011000000000000000000001155555510008888800000d000000000001010100100100100100101010100000000000000
00099909f0ffff00f0fff0000fff00f0111111111111111111111111155551100008880000000000110000001111111111111111111111110111111111111111
009444900fffff400ff6f60005f5ff0011111111111111111111111101551100000080000000d000111000000111111111111111111111100000000000000000
0000000000400000800000000000000000000000000000000000000000000000000aa00000000000000000000000000000000000000000000000000000000000
000008000880084080000088000008000000000000000000000000000000060600aaaa00066666600cccccc0099999900bbbbbb000000000022222200dddddd0
0008480008400080000000000008e8000008e0000000000000000000000006060aaaaaa0066666600cccccc0099999900bbbbbb056056056022222200dddddd0
008888800d0000d00000000000888880008e8800000e00000000000060600666aaaaaaaa066666600cccccc0099999900bbbbbb08e08e08e022222200dddddd0
0048848000000000000000000028828000088200008880000000000006000006000aa000066666600cccccc0099999900bbbbbb08e58e58e022222200dddddd0
000444000880000800000000000222000000200000020000000e000060600006000aa000066666600cccccc0099999900bbbbbb088088088022222200dddddd0
000000000d800d80800000080000000000000000000000000000000000000000000aa000066666600cccccc0099999900bbbbbb055055055022222200dddddd0
0000000000d00d00880000000000000000000000000000000000000000000000000aa00000000000000000000000000000000000000000000000000000000000
00000770700000770000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
70000600007700667000007000000000000000000000000000060000007700007000000000000000000000000000000000000000000000000000000011111110
00770000006600000000006700000000000000000000000000000700006000006600000000000000000000000000000000000000000000000000000000000010
07766000000000000000000000000000000000000000000000707700000000000000700000000000000000000000000000000000000000000000000000000010
0677770000000000000000000000000000000000000000000777770007007000000060000000000007000000c00000000000000007000000c000000000000010
077776000000000700000000007770000000770000000070006676007700600000000000000c0000c60000000000007007000000c60000000000007000000010
0076600700700000000000700777600077006770070000600000660006700000070000000077c0000c00770000000000c6000c000c0077000000000011111110
0000000676607000070007607667770076000660000000000000060000000000060000000c766cc0000006c0000000000c00c7c0000006c00000000000000000
33333333666666660000000000000000000000000000000001111110000000000000000000100000001000000000100000010000000100000010000001010100
44433544776677760000000000000000000000000000000000000000000000000000000000110100001000010101101010011010000100101010000001010100
9444554477c67c760000000000000000000000000000000000111100000000000000000000101010001000001011110100011101010100010110000001010100
44444449ccc677760000000000000000070007000000000001111110000011111111000011111111111111111111111111111111111111111111111101010100
44594444ccc6cccc05666650000000000700070000000000001001100001ccc58888100000010111100010101000000000000000001010100101100001010100
44459444777cc7c600d00d00000000006760676000000000010111100015cccc5885d10000001011010011010011111111111100000101100010100001010100
444444447c76cccc000dd00000000000576d576d006666000011110000195cc5885dd10000000010000010000111111111111110000000100000100001010100
44444444777ccccc00d00d0005666650555d555d05555550000000000019955355ddd10000000010000010000111010110101110000000100000100001010100
0019995388008088888ee88888eee8883355d1000000000000000000011000000000011001010100001665dd5cccc1000101010000000d1116d6000001100000
001995330000000000822000008888223566510000000000000000000110000000000110010101000011111111111100010101000000061d16d6000001100000
001553350000000000000000000282005666610000000000000000000110000000000110010101000000000000000000010101000000066116d6000001100000
0018855c000000000000000000000000c56551000000000d10000000011000000000011001010100000000000000000001010100000000660666000001100011
001885cc0000000000000000000000005d5331000000000d10000000011000000000011011010101111111111111111111010100000000160100000001100000
00185655000000000000000000000000ddd5310000000dd11dd0000001100000000001100101010001010010010100100101010000000dddd110000001101111
0015665d0000000000000000000000005d553100000001dd1110000001100000000001101101010111111111111111111101010000000dddd110000001101111
001665dd000000000000000000000000d5cc5100000001dd1666000001100000000001100101010001100110011001100101010000000dddd110000001100000
ddddddddd0d0d0d00000000000000110010101000d5d65d655056d5d0dd56d5d5dd556d06d515151d51dd1d55dd515510111111d51dd1d5d51dd1d5000000000
6666666660606060606060601111011001010100555dd055555555055550dd505550555501111110011111011111111000101110111110101111101000000700
66666666606060600000000000000110010101006505055000500650505500055005005d00101110001010011011010000100100010100100101001000000000
ddddddddd0d0d0d0d0d0d0d01111011001010100d50011010000000150001100010110d600100100000010077011010000000100000100700001007007000000
00000000000000000000000000000110010101010501111101011011011111011111115d00000100000010000001000000000000000100000001000007000700
00000000000000000000000011110110010101005500111111111011111111111111050500000000000070000007000000000000000700000007000007707770
00000000000000000000000011110110010101016051111111101111111111111101155500000000000000000000000000000000000000000000000007777770
0000000000000000000000000000011001010100d501111111111101111111110111105d00000000000000000000000000000000000000000000000056665555
066666600666666001111110000000000000000000000000000000000d5d75d755057d5d0dd57d5d5dd557d0555555555555555555555555555555550d5d75d7
66666666666666660010111000000000000000000000000000000000555dd055555555055550dd50555055551111000dddddd00010111111110100dd555dd055
600000066000000600100100000111000000000000000000001110006505055000500750505500055005005d0111dd7ddd7dd7d01811111111111dd775050550
60000006600000060000010000111000000000000001110000011100d50011010000000150001100010110d707d8ddd17008dddd8e80100e8078ddd1d5001101
600000066000000600000000001110000100001000001110000111000501111101011011011111011111115ddd8e8011111e817dd8d00078dd8e871105011111
60011006600ee006000000000011100001100110010001110001110055001111111110111111111111110505dd08000011111110dddddddd7dd8001055001111
6011110660eeee06000000000111110011111110111001110011111060511111111011111111111111011555000000001001000008ddd7ddd070000070511111
011111100eeeeee00000000011111111111111111111111111111111d501111111111101111111110111105d00000000000000000e87000000000000d5011111
05dd515510d51dd1d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111000111110100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01011010000010100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07011010000000100700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000010101010101000000000101010000000101010101010000000000000000000000000000000000000000000000000000000000000001001010000000010101010101010101010100000001010101010101010101010100000101010010101011010101010100000001010101010010101010101010101
1010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6060606060606060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000818181810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001710000001900007101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000420000000000700000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070010000000000000000000000000170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414100000040404000004000000045010000000000000000000000000071000040404040000000000000000000000000000000000000000000000000000040400000000042000042000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000005000000000100000040402700000000000000000000004040000040000000000000000000000000000000000000000000000000000000000000000000001740404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000404141000000000000010000404000000000000000400000000000000000000000000000000000000000000000000000000000000000000000170000001700004141414141410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000414040404000000000002801704200400000000000000000000000000000000000000000000000000000000000000000000040404000000119000000000000000019010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000004040000000000000000000000000000000404141414100404040000000000000000000000000000000000000000000000000000000000000000000000000004141000000000000000041410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000004141414040400000000040000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000017119000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0042000000000000000000004100000040404000000000000042000000004040000000000000000100000000000000000000000000000000000000000000000000000000000041414141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040000000400001000100004100000000000000180000000140404000000040000000006060604040400000000000000000000000000000000000000000000000000071000000000000000071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000400040404000004100404000000000000040404040000000000000000000180000000000000000000000000000000000000000000000000000000000004040400000190000004040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000404000400000000000004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000404000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000040420000000000410000001770014500420000007100000001000042000000002e00000000000001000000012700280029002a002b002c002d012e70000001004200000000420001000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010000000000000000000001000041414141414141414140404040404040404044404041414141404040404040404040404040404040404040404040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0014151516000001010000141515160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
711b1c1c1d1e656667683f1b1c1c1d7100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6568474846496c69696a4e464748656800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6c4f50544f5556575855564f50544f6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00595a5b5c5d5e5f635d5e645a5b640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0065666666666667667879666667680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0069696c6c6a6c69696c696c696c6c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1900010000000000000000000001001900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6566666768001900001900777978797a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6a69696b690077796768006d6969696e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000006b6c696900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000100427374757642000100007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68007778797a7b7c7d7e7f78787a007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6900696c696c000000006a696c69006d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444444444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100001a0501804014040130301273012720117200f710107101072010520105301053012540135401654018050190401a5401d5301e5302052023520275100000000000000000000000000000000000000000
0003000000660142101322012330113400f3500c440094400a3300733005320032200121001210052000420001200032000320016200162001620016200162001b2001d2001f2002b20030200352003520000000
01010000170501a5501b5401d5401e7401f7402173022730237202472025720267102771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000025050255402a5202a5202f5202f5103671036710007000070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003e5503d66039670316702a550236601d6601966015540106600d6500c6500b5500d6500f6401164013140156301713018630182201762016220126200f3100d6100a3100861005410036100241000000
010500000c5700c0300c01000110001200013000140001500c5700c0300c01000110001200013000140001500f5700f0300f01003110031200313003140031501157011030110100511005120051300514005150
010500001255012030061100612012550120300614006150115501103012510120100f5500f0301151011010115501103005110051200f5500f03003140031500c5500c0300f5100f0100a5500a0300c5100c010
010500000c3200c71000710007100a3200071000710007100f3300f7100371003710113401172005710057100c3300c03011310117130a3300a0300c3100c0100f3300f0300a3100a01011330110300f3100f010
010500000c4300c03000710007100c2300c03000710007100c4300c0300c2300c0200f4300f0300c2100c0100c4300c03000710007100c2300c03011430110300c4300c0300f2300f0300c4300c0300071000710
010500000c4300c03000710007100c2300c03000710007100c4300c0300c2300c0300f4300f03003710037100c4300c0300f2100f0100a4300a0300a2200a0300a7100a7100c4300c0300c2200c0300071000710
010500000c4300c03000710007100c2300c03000710007100c4300c0300c2300c0300f4300f0300c2100c0101243012030122301203011430110300f2300f03011430110300f2300f0300c4300c0300a2300a030
01050000093730000000000000003c225000000000000000006150000000605000003c214000000000000000246730000000000000000935300000246050000000615000000c605000003c225000000000000000
01050000093730000000000000003c2250000000000000000062500000006050000009373000000000000000246730000000000000000061500000246050000000625000000c6050000024673000000000000000
01050000093730000000000000003c225000000000000000006150000000605000003c214000000000000000006150000000000000000935300000246050000000615000000c605000003c225000000000000000
01050000093730000000000000003c2250000000000000000061500000006050000009373000003c21400000246730000000000000000935300000246050000000615000000c605000003c225000000000000000
01050000093730000000000000003c2250000000000000000061500000006050000009373000000937300000246730000000000000000937300000093030000009373000000c605000003c225000000000000000
01050000093730000000000000003c22500000000000000000615000000060500000093730000009373000002467300000000000000009373000000930300000246730000024623000003c225000002461300000
010500002f230303113021230222302223032230232303422f0103001130112300122e2402e3102b2302e3102d2402e2212b0102b0102b2402d010292302b0102a2402b2412901029010292402a0102723029010
01050000292402a331270102701029240293102a0102a01026240273312901029010292402933026010270112624027331290102901024240243302601027011292402a33124010240103023030320290102a011
01050000304002e4002b4002740030210000002a21029200262302733127212272222722227322272322734229240293302701027010272302733029010290102424024330270102701023230243212421224222
0105000000000000000000000000222402231024230243102f240303302401024010222402231024230243102d2302e3312e2122e2222b2402b3102e2302e3102b2402b3102e2302e31030230303213051500000
01050000000000000000000000002e3303033130312303222e3300000000000000002b3300000000000000003233033331333123332233312334223333233412303300000000000000002e330000000000000000
01050000000000000000000000002e3303033130312303222e3300000000000000002b3300000000000000002e330303313031230322303123042230332304122e3300000000000000002b330000000000000000
0105000026330273312731227322293300000000000000002b3300000000000000002933000000000000000000000000000000000000213302233122310223202433000000000000000027330000002433000000
01050000283302933129310293202b3302b3000000000000273300000000000000002433000000000000000028330293312931029320273300000000000000002a3302b3312b3122b3222b3122b4222b3322b412
01050000292302a321270102701029230293102a0102a01026230273212901029010292302932026010270112623027321290102901024230243201840024400224001f40024410245101f20024200222001f200
01050000292302a321270102701029230293102a0102a010262302732129010290102b2302b32026010270112f230303212b0102b010000000000030410305100000000000000000000030410305100000000000
01050000283302933129310293202b3302b40027400244002733024400224001f4002433024400224001f40021330223312231022320223122242222332224322333024331243122432224312244222433224412
__music__
01 41050d44
00 41060c44
00 41050d44
00 41060c44
00 41050d44
00 41070c44
00 41050d44
00 41070c44
00 41050b11
00 41060c12
00 41050b13
00 41060c14
00 41050b44
00 41070c19
00 41050b44
00 41070c1a
00 41080e16
00 41090f17
00 41080e15
00 410a0f18
00 41080e16
00 41090f17
00 41080e15
02 410a101b
