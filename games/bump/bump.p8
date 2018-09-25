pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
flg_solid=0
flg_ice=1

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

win_threshold=9


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


title_w=5*8
title_h=2*8
title_dx=25
title_dy=-3
title_ssx=11*8
title_ssy=12*8

function draw_title(s)
 cls()
 local f=flr(frame/6)%3

 if f==1 then
  draw_title_frame1()
 else
  pal(7,12)
  -- srand(f)
  draw_title_frame2(-1)
  draw_random_line(7)

  if f==2 then
   pal(7,7)
   fillp(0x5a5a)
   rectfill(title_dx-3,title_dy+8,title_dx+2,title_dy+12,7)
   fillp(0xa0a0)
   rectfill(title_dx+60,title_dy+30,title_dx+66,title_dy+34,12)
   rectfill(title_dx+62,title_dy+28,title_dx+68,title_dy+32,7)
  end

  pal(7,8)
  -- srand(f)
  draw_title_frame2(1)
  srand(f+1)
  draw_random_line(7)

  pal()
  -- srand(f)
  draw_title_frame2(0)
  -- srand(f+2)
  draw_random_line(0)
 end

 palt(0,true)

 fillp()
 glitch_str(s)
end

function glitch_str(s)
 if (frame%10)<3 then
  aberration_str("- pixelgore 2018 -",title_dy+39)
  aberration_str("- space=start -",title_dy+48)
  if mode==mode_title then
   aberration_str("\x8e throw",title_dy+61,86)
   aberration_str("\x97 join/jump",title_dy+61,10)
  end
  if (s!=nil) aberration_str(s,title_dy+96)
  for i=0,1 do
   draw_random_line(0,title_dx+15,title_dy+33,1)
   draw_random_line(7,title_dx+15,title_dy+33,1)
   draw_random_line(12,title_dx+15,title_dy+33,1)
   draw_random_line(8,title_dx+15,title_dy+33,1)
  end
 elseif (frame%10<8) then
  center_print("- pixelgore 2018 -",title_dy+39)
  center_print("- press space to start -",title_dy+48)
  if mode==mode_title then
   center_print("\x8e throw",title_dy+61,86)
   center_print("\x97 join/jump",title_dy+61,10)
  end
  if (s!=nil) center_print(s,title_dy+96)
 end
end

function center_str_x(s)
 return 64-(#s*4)/2
end

function center_print(s,y,x)
 if (x==nil) x=center_str_x(s)
 print(s,x,y,7)
end

function aberration_str(s,y,x)
 if (x==nil) x=center_str_x(s)
 print(s,x+mrnd(2),y+mrnd(2)+1,12)
 print(s,x+mrnd(2),y+mrnd(2),8)
 print(s,x,y,7)
end

function draw_title_frame1()
 pal(7,12)
 sspr(title_ssx,title_ssy,title_w,title_h,title_dx-1,title_dy,title_w*2,2*title_h)
 pal(7,8)
 sspr(title_ssx,title_ssy,title_w,title_h,title_dx+1,title_dy,title_w*2,2*title_h)
 pal()
 sspr(title_ssx,title_ssy,title_w,title_h,title_dx,title_dy,title_w*2,2*title_h)
end

function draw_random_line(col,offx,offy,cnt)
 if (offx==nil) offx=title_dx
 if (offy==nil) offy=title_dy+10
 if (cnt==nil) cnt=5

 for i=0,cnt do
  palt(col,false)
  local x=rnd(title_w+10)+offx
  local y=rnd(title_h+5)+offy
  local w=rnd(10)
  line(x,y,x+w,y,col)
  palt()
 end
end

function draw_title_frame2(addx)
 local sy=0
 while sy<title_h do
  local sx=0
  local dh=min(title_h-sy,flr(rnd(3)+3))

  local offy=mrnd(1)
  while sx<title_w do
   local dw=min(title_w-sx,flr(rnd(5)+5))
   local offx=mrnd(1)
   offy+=mrnd(.5)
   sspr(title_ssx+sx,title_ssy+sy,dw,dh,title_dx+sx*2+offx+addx,title_dy+sy*2+offy,dw*2,dh*2)
   sx+=dw
  end

  sy+=dh
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

   -- printh("self.x "..tostr(self.x).." amount "..tostr(amount).." solid "..tostr(solid).." actor "..tostr(actor))

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

   -- printh(tostr(self.name).." pos "..tostr(self.x)..","..tostr(self.y).." amount "..tostr(amount).." solid "..tostr(solid).." actor "..tostr(actor))
   -- printh(tostr(self.name).." aabb "..tostr(self.aax)..","..tostr(self.aay).. "-"..tostr(self.bbx)..","..tostr(self.bby))

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
 map(self.x+16,self.y,0,0,self.dim_x,self.dim_y,flg_solid+1+16)
end

function cls_room:spawn_player(input_port)
 local max_spawn_dist=0
 local spawn_pos
 for pos in all(self.spawn_locations) do
  local min_dist=10000
  for p in all(players) do
   local dist=sqrt((pos.x-p.x)^2+(pos.y-p.y)^2)
   if (dist<min_dist) min_dist=dist
  end
  for p in all(spawn_points) do
   local dist=sqrt((pos.x-p.x)^2+(pos.y-p.y)^2)
   if (dist<min_dist) min_dist=dist
  end
  if min_dist>max_spawn_dist then
   spawn_pos=pos
   max_spawn_dist=min_dist
  end
 end

 if (spawn_pos==nil) spawn_pos=rnd_elt(self.spawn_locations)
 local spawn=cls_spawn.init(spawn_pos, input_port)
 connected_players[input_port]=true
 return spawn
end

function is_outside_room(bbox)
 return (bbox.aax<0
   or bbox.bbx>room.bbx
   or bbox.aay<0
   or bbox.bby>room.bby)
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

cls_score_particle=class(function(self,pos,val,c2,c1)
 self.x=pos.x
 self.y=pos.y
 self.spd_x=mrnd(0.2)
 self.spd_y=-rnd(0.2)-0.2
 self.c2=c2
 self.c1=c1
 self.val=val
 self.t=0
 self.lifetime=2
 add(particles,self)
end)

function cls_score_particle:update()
 self.t+=dt
 self.x+=self.spd_x+rnd(.1)
 self.x=mid(rnd(5),self.x,128-rnd(5)-4*#self.val)
 self.y+=self.spd_y
 if (self.t>self.lifetime) del(particles,self)
end

function cls_score_particle:draw()
 bstr(self.val,self.x,self.y,self.c1,self.c2)
end

cls_pwrup_particle=class(function(self,x,y,a,cols)
 self.spd_x=cos(a)*.8
 self.cols=cols
 self.spd_y=sin(a)*.8
 self.x=x+self.spd_x*5
 self.y=y+self.spd_y*5
 self.t=0
 self.lifetime=0.8
 add(particles,self)
end)

function cls_pwrup_particle:update()
 self.t+=dt
 self.y+=self.spd_y
 self.x+=self.spd_x
 self.spd_y*=0.9
 self.spd_x*=0.9
 if (self.t>self.lifetime) del(particles,self)
end

function cls_pwrup_particle:draw()
 local col=self.cols[flr(#self.cols*self.t/self.lifetime)+1]
 circ(self.x,self.y,(2-self.t/self.lifetime*2),col)
end

players={}
connected_players={}
combo_kills={0,0,0,0}
combo_kill_timer={0,0,0,0}
player_cnt=0

start_sprites={1,130,146,226}

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

 self.ghosts={}

 self.nr=player_cnt
 self.power_up=nil
 self.power_up_countdown=nil
 player_cnt+=1

 self.flip=v2(false,false)
 self.input_port=input_port
 self.jump_button=cls_button.init(btn_jump, input_port)
 self.start_spr=start_sprites[self.input_port+1]
 self.spr=self.start_spr

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0

 self.is_teleporting=false
 self.on_ground=false
 self.is_bullet_time=false
 self.is_dead=false
end)

function cls_player:update_bbox()
 if self.power_up_type!=spr_pwrup_shrink and not (solid or actor) then
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

  -- we should actually never collide at the start of the frame
  -- if we are, use the small hitbox
  local solid=solid_at_offset(self,0,0)
  local actor,a=self:is_actor_at(0,0)
  if actor or solid then
   self:update_shrunk_bbox()
  end
 else
  self:update_shrunk_bbox()
 end
end

function cls_player:update_shrunk_bbox()
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

function cls_player:smoke(spr,dir)
 return cls_smoke.init(v2(self.x,self.y),spr,dir)
end

function cls_player:kill()
 if not self.is_dead then
  del(players,self)
  del(actors,self)
  self.is_dead=true
  add_shake(3)
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
 if is_outside_room(self) then
  self:kill()
  sfx(1)
 elseif self.is_teleporting or self.is_bullet_time then
 else
  self:update_normal()
 end
end

function cls_player:update_normal()
 local nr=self.input_port+1

 if combo_kill_timer[nr]>0 then
  combo_kill_timer[nr]-=dt
 else
  combo_kills[nr]=0
 end

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
    sfx(0)
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
  self.spr=self.start_spr
 elseif is_wall_sliding then
  self.spr=self.start_spr+3
 elseif not self.on_ground then
  self.spr=self.start_spr+2
 else
  self.spr=self.start_spr+flr(frame/4)%3
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
    local can_attack=not self.on_ground

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
      self:add_score(0)
     else
      self:add_score(1)
     end
     player:kill()
     sfx(1)
    end)
   end
  end
 end

 local solid=solid_at_offset(self,0,0)
 local actor,a=self:is_actor_at(0,0)
 if actor or solid then
  -- we're still solid, even though we shouldn't
  -- to avoid having the player stuck, we're just gonna kill him
  printh("kill because actor "..tostr(actor).." solid "..tostr(solid))
  self:kill()
  sfx(1)
 end

 for a in all(interactables) do
  if (do_bboxes_collide(self,a)) a:on_player_collision(self)
 end

 if (not self.on_ground and frame%2==0) insert(self.ghosts,{x=self.x,y=self.y})
 if ((self.on_ground or #self.ghosts>6)) popend(self.ghosts)
end

function cls_player:add_score(add)
 local nr=self.input_port+1
 scores[nr]+=add
 if add>=0 then
  combo_kill_timer[nr]=3
  combo_kills[nr]+=1
  if combo_kills[nr]==1 then
   cls_score_particle.init(v2(self.x,self.y),"kill",1,7)
  elseif combo_kills[nr]==2 then
   cls_score_particle.init(v2(self.x,self.y),"double kill",10,1)
  elseif combo_kills[nr]==3 then
   cls_score_particle.init(v2(self.x,self.y),"triple kill",9,1)
  elseif combo_kills[nr]==4 then
   cls_score_particle.init(v2(self.x,self.y),"killing spree",8,7)
   combo_kill_timer[nr]=0
   combo_kills[nr]=0
  end
 end

 if mode==mode_game and scores[nr]>win_threshold then
  winning_player=nr
  end_game()
 end
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
  rectfill(0,0,128,128,7)
  return
 end
 if not self.is_teleporting then
  if (self.power_up_type==spr_pwrup_invisibility and frame%60<50) return
  local dark=0
  for ghost in all(self.ghosts) do
   dark+=12
   darken(dark)
   spr(self.spr,ghost.x,ghost.y,1,1,self.flip.x,self.flip.y)
  end
  pal()

  spr(self.spr,self.x,self.y,1,1,self.flip.x,self.flip.y)

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
 sfx(2)
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
spawn_points={}

cls_spawn=class(function(self,pos,input_port)
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
 add(particles,self)
 add(spawn_points,self)
end)


function cls_spawn:update()
end

function cls_spawn:cr_spawn()
 cr_move_to(self,self.target_x,self.target_y,1,inexpo)
 del(particles,self)
 del(spawn_points,self)
 local player=cls_player.init(v2(self.target_x,self.target_y), self.input_port)
 player.is_doppelgaenger=self.is_doppelgaenger
 cls_smoke.init(v2(self.x,self.y),spr_full_smoke,0)
end

function cls_spawn:draw()
 spr(start_sprites[self.input_port+1],self.x,self.y)
end

spr_spikes=68

cls_spikes=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,3,8,5)
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:on_player_collision(player)
 if player.power_up!=spr_pwrup_invincibility and not player.is_dead then
  player:kill()
  sfx(1)
  player:add_score(-1)
  make_gore_explosion(v2(player.x,player.y))
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.x,self.y)
end

spr_tele_enter=216
spr_tele_exit=200
tele_exits={}

cls_tele_enter=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,4,4,1,4)
end)
tiles[spr_tele_enter]=cls_tele_enter

function cls_tele_enter:on_player_collision(player)
 if player.on_ground and not player.is_teleporting then
  sfx(33)
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
 spr(self.tile+(frame/4)%3,self.x,self.y)
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
 spr(self.tile+(frame/4)%3,self.x,self.y)
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

pwrup_counts=0

function cls_pwrup_dropper:update()
 if self.item==nil then
  -- increment time. spawn when time's up
  self.time=(self.time%(self.interval))+1
  if self.time>=self.interval then
   if pwrup_counts<max_count then
    local spr_idx=power_up_tiles[flr(rnd(#power_up_tiles))+1]
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
 self.offset=flr(rnd(30))
end)

function cls_pwrup:on_player_collision(player)
 if player.power_up!=nil then
  player:clear_power_up()
 end

 self:on_powerup_start(player)
 player.power_up=self
 player.power_up_type=self.tile
 player.power_up_countdown=powerup_countdowns[self.tile]
 sfx(3)

 if self.tile!=spr_bomb then
  local x=self.x
  local y=self.y
  local radius=20
  add_cr(function ()
   for i=0,1,0.1 do
    local p=cls_pwrup_particle.init(self.x+4,self.y+4,i,powerup_colors[self.tile])
    p.spd_x*=3
    p.spd_y*=3
   end
   for i=0,20 do
    local r=outexpo(i,radius,-radius,20)
    circfill(x+4,y+6,r,powerup_colors[self.tile][1])
    yield()
   end
  end, draw_crs)
 end

  del(interactables,self)
end

function cls_pwrup:on_powerup_start(player)
end

function cls_pwrup:on_powerup_stop(player)
end

function cls_pwrup:draw()
 if self.tile==spr_bomb then
  if (rnd(1)<0.3) cls_fuse_particle.init(v2(self.x,self.y))
  spr(self.tile,self.x,self.y)
 else
  spr(self.tile+(frame/8)%3,self.x,self.y)
  if (frame+self.offset)%40==0 then
   for i=0,1,0.1 do
    cls_pwrup_particle.init(self.x+4,self.y+4,i,powerup_colors[self.tile])
   end
  end
 end
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

spr_pwrup_doppelgaenger=197
powerup_colors[spr_pwrup_doppelgaenger]={8,2,1}

spr_pwrup_invincibility=155
powerup_colors[spr_pwrup_invincibility]={9,8,7,2}
powerup_countdowns[spr_pwrup_invincibility]=10

spr_pwrup_superspeed=41
powerup_colors[spr_pwrup_superspeed]={6,6,5,1}
powerup_countdowns[spr_pwrup_superspeed]=10

spr_pwrup_superjump=42
powerup_colors[spr_pwrup_superjump]={12,13,2,1}
powerup_countdowns[spr_pwrup_superjump]=15

spr_pwrup_gravitytweak=43
powerup_colors[spr_pwrup_gravitytweak]={9,8,2,1}
powerup_countdowns[spr_pwrup_gravitytweak]=30

spr_pwrup_invisibility=178
powerup_colors[spr_pwrup_invisibility]={9,8,2,1}
powerup_countdowns[spr_pwrup_invisibility]=5

spr_pwrup_shrink=139
powerup_colors[spr_pwrup_shrink]={11,3,6,1}
powerup_countdowns[spr_pwrup_shrink]=10

-- start offset for the item sprite values
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
 -- spr_pwrup_invisibility,
 spr_pwrup_invisibility,
 spr_pwrup_invisibility,
 spr_pwrup_shrink,
 spr_pwrup_shrink,
}

spr_bomb=23
cls_bomb_pwrup=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)
tiles[spr_bomb]=cls_bomb_pwrup

function make_blast(obj,radius)
 local x=obj.x
 local y=obj.y
 add_cr(function ()
  for i=0,20 do
   local r=outexpo(i,radius,-radius,20)
   circfill(x+4,y+6,r,7)
   yield()
  end
 end, draw_crs)
 add_shake(5)
 sfx(4)
 for p in all(players) do
  if p.power_up!=spr_pwrup_invincibility then
   local dx=p.x-x
   local dy=p.y-y
   local d=sqrt(dx*dx+dy*dy)
   if d<radius then
    if obj.player!=nil then
     if p.input_port!=obj.player.input_port then
      obj.player:add_score(1)
     else
      obj.player:add_score(-1)
     end
    end
    p:kill()
    make_gore_explosion(v2(p.x,p.y))
   end
  end
 end
end

function cls_bomb_pwrup:on_powerup_start(player)
 local bomb=cls_bomb.init(player)
end

fuse_cols={8,9,10,7}
cls_fuse_particle=class(function(self,pos)
 self.x=pos.x+6
 self.y=pos.y+1
 local v=angle2vec(mrnd(0.5))*0.2
 self.spd_x=v.x
 self.spd_y=v.y
 self.t=0
 self.lifetime=rnd(1)
 add(particles,self)
end)

function cls_fuse_particle:update()
 self.t+=dt
 self.x+=self.spd_x+rnd(.5)
 self.y+=self.spd_y+mrnd(.3)
 if (self.t>self.lifetime) del(particles,self)
end

function cls_fuse_particle:draw()
 circfill(self.x,self.y,.5,fuse_cols[flr(#fuse_cols*self.t/self.lifetime)+1])
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
 if (rnd(1)<0.5) cls_fuse_particle.init(v2(self.x,self.y))

 self.time-=dt
 if self.time<0 then
  make_blast(self,45)
  del(actors,self)
 end

 if self.is_thrown then
  local solid=solid_at_offset(self,0,0)
  local actor,a=self:is_actor_at(0,0)
  if not self.is_solid and not solid and not actor then
   -- avoid a bomb getting stuck on a wall when thrown
   self.is_solid=true
  end

  if self.x<=0 then
   self.spd_x=0
   self.x=1
  end
  if self.y<=0 then
   self.y=1
   self.spd_y=0
  end
  if self.x>=119 then
   self.x=119
   self.spd_x=0
  end
  if self.y>=119 then
   self.y=119
   self.spd_y=0
  end

  local gravity=0.12
  local maxfall=2
  self.spd_y=appr(self.spd_y,maxfall,gravity)
  cls_actor.move_x(self,self.spd_x)
  cls_actor.move_y(self,self.spd_y)

  if self.is_solid then
   if tile_flag_at_offset(self,flg_solid,0,1) then
    self.spd_y*=-0.8
   elseif tile_flag_at_offset(self,flg_solid,sign(self.spd_x),0) then
    self.spd_x*=-0.85
   end
  end
 elseif self.player.is_dead then
  del(actors,self)
 else
  self.x=self.player.x
  self.y=self.player.y-8
  if btnp(btn_action,self.player.input_port) then
   self.is_thrown=true
   self.spd_x=(self.player.flip.x and -1 or 1) + self.player.spd_x
   self.spd_y=-1
  end
 end
end

function cls_bomb:draw()
 spr(spr_bomb,self.x,self.y)
end

for i=0,4 do
 add(power_up_tiles,spr_bomb)
end


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

winning_player=nil

mode_title=0
mode_game=1
mode_end=2
mode_transition=3

mode=mode_title

function make_transition(mid_cb,end_cb)
 add_cr(function()
  local col=7
  local duration=15
  for i=0,duration do
   palt(col,false)
   local radius=inexpo(i,0,128,duration)
   circfill(64,64,radius,col)
   palt()
   yield()
  end
  if (mid_cb!=nil) mid_cb()
  for i=0,duration do
   palt(col,false)
   local radius=128-inexpo(i,0,128,duration)
   circfill(64,64,radius,col)
   palt()
   yield()
  end
 if (end_cb!=nil) end_cb()
 end, draw_crs)
end

function start_game()
 -- this is a pretty inelegant way of resetting global state
 interactables={}
 actors={}
 players={}
 particles={}
 fireflies_init(v2(16,16))
 crs={}
 pwrup_counts=0
 for i=1,4 do
  scores[i]=0
 end
 make_transition(function()
  mode=mode_transition
  room=cls_room.init(v2(0,16),v2(16,16))
 end, function()
  mode=mode_game
  for input,v in pairs(connected_players) do
   if v==true then
    room:spawn_player(input)
   end
  end
 end)
end

function end_game()
 make_transition(nil,function()
  mode=mode_end
 end)
end

function is_space_pressed()
 return stat(30) and stat(31)==" "
end

function _init()
 poke(0x5f2d,1)
 room=cls_room.init(v2(0,0),v2(16,16))
 room:spawn_player(p1_input)
 room:spawn_player(p2_input)
 -- room:spawn_player(p3_input)
 -- room:spawn_player(p4_input)
 fireflies_init(v2(16,16))
 music(0)
end

function update_a(a) a:update() end
function draw_a(a) a:draw() end

function _draw()
 frame+=1

 cls()
 if mode==mode_title then
  draw_title()
  if is_space_pressed() then
   start_game()
  end
 end

 if mode==mode_transition then
   tick_crs(draw_crs)
 else
  if mode!=mode_end then
   camera(camera_shake.x,camera_shake.y)
   room:draw()
   foreach(interactables, draw_a)
   foreach(environments, draw_a)
   foreach(static_objects, draw_a)
   draw_actors()

   fireflies_draw()
   foreach(particles, draw_a)
   tick_crs(draw_crs)

   if mode==mode_game then
    local entry_length=30
    palt(0,false)
    rectfill(0,120,128,128,0)
    for i=0,#scores-1,1 do
     print(
     "p"..tostr(i+1)..": "..tostr(scores[i+1]),
     i*entry_length+10,121,7
     )
    end
    palt()
   end
  else
   draw_title("player "..tostr(winning_player).." won!")
   local _spr=start_sprites[winning_player]+flr(frame/8)%3
   local sx=_spr%16*8
   local sy=flr(_spr/16)*8
   sspr(sx,sy,8,8,64-16,title_dy+56,32,32)

   if is_space_pressed() then
    run()
   end
  end
 end
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 check_for_new_players()

 for a in all(actors) do a:update_bbox() end
 tick_crs()
 foreach(environments, update_a)
 update_actors()
 foreach(particles, update_a)
 foreach(interactables, update_a)
 update_shake()

 fireflies_update()
end


__gfx__
00000000000000000000000088555500000000000000000000000000000000000000000000000000000000111100000000000111111111111110000000000000
00000000855550000000000000566670008555500000000000000000000000000000000000000000000001111110000000001111111111111111000000000000
00700700856660000855550000511170008566670000000000000000000000000000000000000000000011000011000000011000000000000001100000000000
0007700005111700085666700dd61670000511170000000000000000080000000000000000000000000110011001100000110001100000011000110000000000
0007700005616700005111700dd55500000561670855500008555000005557000855570000000000001100011000110001100001100000011000011000000000
00700700dd5557000dd6167000055000000dd55600111700001117000d1117000011170000000000011000000000011011000000000000000000001100000000
00000000dd5500000dd5500000600600000dd5600d5157000d5157000051500000d1560000000000011111111111111011111111111111111111111100000011
00000000006600000006060000000000000000000060600000660000060006000000000000000000000000000000000000000000000000000000000000000111
000000000000000000000000000000000000011111111111111000000000790000288820000dd000000000001111111111111111111111110000000000000000
00000000000000000000000000000000000011111111111111110000000760a00288878200d00d00000000001010100100100100100101010111111111111111
000000000000000000000000000000000001100000000000000110000155110008888e8e0d0000d0000000001110000000000000000001110100000000000000
0000000000000000000000000000000000110001100000011000110016655110088888880d000d00000000001000000000000000000000010100000000000000
00000000000000000000000000000000011000011000000110000110566555100288888200d0d000000000001110000000000000000001110100000000000000
0000000000000000000000000000000011000000000000000000001155555510008888800000d000000000001010100100100100100101010100000000000000
00000000000000000000000000000000111111111111111111111111155551100008880000000000110000001111111111111111111111110111111111111111
0000000000000000000000000000000011111111111111111111111101551100000080000000d000111000000111111111111111111111100000000000000000
00000000004000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000800088008408000008800000800000000000000000000000000000000000111100000000000001111000001111000000000000000000000000000000000
0008480008400080000000000008e8000008e0000000000000000000000000000233300000111100002333000002333000000000000000000000000000000000
008888800d0000d00000000000888880008e8800000e0000000000000000000073b3b60000233300073b3b600073b3b600000000000000000000000000000000
004884800000000000000000002882800008820000888000000000000000000003333000073b3b60003333000003333000111000001110000011100000111000
000444000880000800000000000222000000200000020000000e0000000000000055000000333300000110000000555307b3b00007b3b00007b3b00007b3b000
000000000d800d808000000800000000000000000000000000000000000000000011000000011000003003000000113000555000005550000055500000555300
0000000000d00d008800000000000000000000000000000000000000000000000033000000030300000000000000000000303000003300000300030000000000
00000770700000770000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
70000600007700667000007000000000000000000000000000060000007700007000000000000000000000000000000000000000000000000000000011111110
00770000006600000000006700000000000000000000000000000700006000006600000000000000000000000000000000000000000000000000000000000010
07766000000000000000000000000000000000000000000000707700000000000000700000000000000000000000000000000000000000000000000000000010
0677770000000000000000000000000000000000000000000777770007007000000060000000000007000000c00000000000000007000000c000000000000010
077776000000000700000000007770000000770000000070006676007700600000000000000c0000c60000000000007007000000c60000000000007000000010
0076600700700000000000700777600077006770070000600000660006700000070000000077c0000c00770000000000c6000c000c0077000000000011111110
0000000676607000070007607667770076000660000000000000060000000000060000000c766cc0000006c0000000000c00c7c0000006c00000000000000000
00000000000000000000000000000000000000000000000001111110000000000000000000100000001000000000100000010000000100000010000001010100
00000000000000000000000000000000000000000000000000000000000000000000000000110100001000010101101010011010000100101010000001010100
00000000000000000000000000000000000000000000000000111100000000000000000000101010001000001011110100011101010100010110000001010100
00000000000000000000000000000000070007000000000001111110000011111111000011111111111111111111111111111111111111111111111101010100
000000000000000005666650000000000700070000000000001001100001ccc58888100000010111100010101000000000000000001010100101100001010100
000000000000000000d00d00000000006760676000000000010111100015cccc5885d10000001011010011010011111111111100000101100010100001010100
0000000000000000000dd00000000000576d576d006666000011110000195cc5885dd10000000010000010000111111111111110000000100000100001010100
000000000000000000d00d0005666650555d555d05555550000000000019955355ddd10000000010000010000111010110101110000000100000100001010100
001999530000000000000000000000003355d1000000000000000000011000000000011001010100001665dd5cccc10001010100000000000000000001100000
00199533000000000000000000000000356651000000000000000000011000000000011001010100001111111111110001010100000000000000000001100000
00155335000000000000000000000000566661000000000000000000011000000000011001010100000000000000000001010100000000000000000001100000
0018855c000000000000000000000000c56551000000000000000000011000000000011001010100000000000000000001010100000000000000000001100011
001885cc0000000000000000000000005d5331000000000000000000011000000000011011010101111111111111111111010100000000000000000001100000
00185655000000000000000000000000ddd531000000000000000000011000000000011001010100010100100101001001010100000000000000000001101111
0015665d0000000000000000000000005d5531000000000000000000011000000000011011010101111111111111111111010100000000000000000001101111
001665dd000000000000000000000000d5cc51000000000000000000011000000000011001010100011001100110011001010100000000000000000001100000
ddddddddd0d0d0d00000000000000110010101000d5d65d655056d5d0dd56d5d5dd556d06d515151d51dd1d55dd515510111111d51dd1d5d51dd1d5000000000
6666666660606060606060601111011001010100555dd055555555055550dd505550555501111110011111011111111000101110111110101111101000000700
66666666606060600000000000000110010101006505055000500650505500055005005d00101110001010011011010000100100010100100101001000000000
ddddddddd0d0d0d0d0d0d0d01111011001010100d50011010000000150001100010110d600100100000010077011010000000100000100700001007007000000
00000000000000000000000000000110010101010501111101011011011111011111115d00000100000010000001000000000000000100000001000007000700
00000000000000000000000011110110010101005500111111111011111111111111050500000000000070000007000000000000000700000007000007707770
00000000000000000000000011110110010101016051111111101111111111111101155500000000000000000000000000000000000000000000000007777770
0000000000000000000000000000011001010100d501111111111101111111110111105d00000000000000000000000000000000000000000000000056665555
000000000000000001111110000000000000000000000000000000000d5d75d755057d5d0dd57d5d5dd557d0555555555555555555555555555555550d5d75d7
00000000000000000010111000000000000000000000000000000000555dd055555555055550dd50555055551111000dddddd00010111111110100dd555dd055
000000000000000000100100000111000000000000000000001110006505055000500750505500055005005d0111dd7ddd7dd7d01811111111111dd775050550
00000000000000000000010000111000000000000001110000011100d50011010000000150001100010110d707d8ddd17008dddd8e80100e8078ddd1d5001101
000000000000000000000000001110000100001000001110000111000501111101011011011111011111115ddd8e8011111e817dd8d00078dd8e871105011111
0000000000000000000000000011100001100110010001110001110055001111111110111111111111110505dd08000011111110dddddddd7dd8001055001111
0000000000000000000000000111110011111110111001110011111060511111111011111111111111011555000000001001000008ddd7ddd070000070511111
00000000000000000000000011111111111111111111111111111111d501111111111101111111110111105d00000000000000000e87000000000000d5011111
5dd51551d51dd1d5008887000000000000888700008887000000000000000000000000000000000000000000003bb300003bb300003773000000000000000000
1111111001111101088788800088870008878880088788800000000000000000000000000000000000000000003bb300003bb300003773000000000000000000
1011010000101001088888700887888008888870088888700000000000000000000000000000000000000000003bb3000037b300003b73000000000000000000
701101000000100707887880088888700788788007887880000870000008700000087000008700000000000037bbb3333b7773333bbbb3330000000d10000000
0001000000001000004b4b0007887880004b4b00004b4b000078880000788800007888000788800000000000377bb3333bb773333bbbb3330000000d10000000
000700000000700000ffff00004b4b00000ff000000ffff0004b4b00004b4b00004b4b0004b4b000000000000377b33003bb733003bbb33000000dd11dd00000
0000000000000000000ff000000ff00000f00f00000fff00000ff000000ff000000ff00000ffff000000000000377300003bb300003bb300000001dd11100000
0000000000000000000ff000000f0f000000000000000000000f0f00000ff00000f00f000000000000000000000370000003b0000003b000000001dd16660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001777cc111ccc77111ccccc1100000d1116d60000
0000000000000000440444000000000044044400440444000000000000000000000000000000000000000000177ccc111cc777111ccccc110000061d16d60000
000000000000000040447770440444004044777040447770000000000000000000000000000000000000000017cccc111c7777111ccccc110000066116d60000
00000000000000004044575040447770004457504044575000000000000000000000000000000000000000001ccccc1117777c111ccccc110000006606660000
00000000000000000007777040445750000777700007777000444400000444000044440000444400000000001ccccc111777cc111cccc7110000001601000000
00000000000000000000ee0000077770000088000000eee7044171000041710004417100044171000000000001cccc10017ccc1001cc771000000dddd1100000
00000000000000000000880000008800000700700000887004088800004880000008880000088e7000000000001ccc00001ccc000017770000000dddd1100000
00000000000000000000770000007070000000000000000000070700000770000070007000000000000000000001c0000001c0000001700000000dddd1100000
00000000000000000011110000000000000000000000000000000000000110000000000000000000000000000006600000000000000000000000000000000000
000000000000000001cccc1000cccc00000000000011110000011000001cc1000000000000000000000000000066000000000000000000000000000000000000
00000000000000001cccccc10cc77cc0001cc10001cccc10001cc10001c77c100000000000000000000000000660000000000000006000000000000000000000
00000000000000001cccccc10c7777c000cccc001c7777c101c77c1001c77c100000000000000000000000006d00d10d000d1000066000000000000d10000000
00000000000000001cccccc10c7777c000cccc001c7777c101c77c1001c77c100000000000000000000000000dd0d101000d1000666000000000000d10000000
00000000000000001cccccc10cc77cc0001cc10001cccc10001cc10001c77c1000000000000000000000000000dd11d10dd11dd06d00000000000dd11dd00000
000000000000000001cccc1000cccc00000000000011110000011000001cc100000000000000000000000000000d6d1001dd1110d10000000000666ddd100000
00000000000000000011110000000000000000000000000000000000000110000000000000000000000000000006661001dd111d1000000000006d6dd1100000
0000000000000000009999000000000000000000000000000000000000099000003333000003333000333300000d6d100111111d0000000000006d6111d10000
000000000000000009aaaa9000999900000000000099990000099000009aa90003b77b00003b77b003b77b00000d6110001d11d10000000000006661116d0000
00000000000000009aaaaaa909977990009aa90009aaaa90009aa90009a77a9000b70bb0000b70bb00b70bb000d11d10001111d0000000000000001116600000
00000000000000009aaaaaa90977779000aaaa009a7777a909a77a9009a77a9003b703b0003b703b03b703b000d100d100100d10000000000000001666100000
00000000000000009aaaaaa90977779000aaaa009a7777a909a77a9009a77a9000bbbbb000bbbbbb00bbbbb00010000100100d00000000000000006660100000
00000000000000009aaaaaa909977990009aa90009aaaa90009aa90009a77a900bbfff00bbbffff00bbfff0000dddd110dddd1100000000000000ddddd110000
000000000000000009aaaa9000999900000000000099990000099000009aa900bbbff0000bbff000bbbff00000dddd110dddd1100000000000000ddddd110000
000000000000000000999900000000000000000000000000000000000009900003030000030030000033000000dddd110dddd1100000000000000ddddd110000
00000000000000000022220000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000
00000000000000000288882000888800000000000022220000022000002882000000010000000000000000000000000000000000000000000000000000000000
00000000000000002888888208877880002882000288882000288200028778200000000000000010010000000000000000000000000000000000000000000000
00000000000000002888888208777780008888002877778202877820028778200100000000010000000000100000000000000000000000000000000000000000
00000000000000002888888208777780008888002877778202877820028778200100010001010000000010100000000000000000000000000000000000000000
00000000000000002888888208877880002882000288882000288200028778200110111001111010010111100000000000000000000000000000000000000000
00000000000000000288882000888800000000000022220000022000002882000111111001111110011111107777770007700007700777000000777007777770
00000000000000000022220000000000000000000000000000000000000220005777555557775555577755557777777007700007700777700007777007777777
00000000000000000033330000000000000000000000000000000000000330000000000000000000000000007700077007700007700777700007777007700077
000000000000000003bbbb3000bbbb00000000000033330000033000003bb30000000a0000000000000000007700077007700007700770770077077007700077
00000000000000003bbbbbb30bb77bb0003bb30003bbbb30003bb30003b77b3000000000000000a00a0000007777770007700007700770770077077007700077
00000000000000003bbbbbb30b7777b000bbbb003b7777b303b77b3003b77b300a000000000a0000000000a07777777007700007700770770077077007777777
00000000000000003bbbbbb30b7777b000bbbb003b7777b303b77b3003b77b300a000a000a0a00000000a0a07700077007700007700770077770077007777770
00000000000000003bbbbbb30bb77bb0003bb30003bbbb30003bb30003b77b300aa0aaa00aaaa0a00a0aaaa07700077007770077700770077770077007700000
000000000000000003bbbb3000bbbb00000000000033330000033000003bb3000999999009999990099999907777777000777777000770007700077007700000
00000000000000000033330000000000000000000000000000000000000330005777555557775555577755557777770000077770000770007700077007700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000ffff0000000000000ffff00000ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000f5f500000ffff0000f5f500000f5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000288800000f5f500002888000002888000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000288800000288800002888000002888000fff00000fff00000fff00000fff000000000000000000000000000000000000000000000000000
000000000000000000bb000000288800000330000000bbb4005f5000005f5000005f5000005f5000000000000000000000000000000000000000000000000000
00000000000000000033000000033000004004000000334000888000008880000088800000888400000000000000006666600000000000000000000000000000
00000000000000000044000000040400000000000000000000404000004400000400040000000000000000000000006000600000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000600000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000600000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666000666600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000006000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000060000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000600000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000
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
0000000000000000000010101010101000000000101010000000101010101010000000000000000000000000000000000000000000000000000000000000001000000000000010101010101010101010100000001000001010101010100000100000101010010101011010101010100000001010101010010101010101010101
1010000000000000000000000000101000000000000000000000000000001010000000000000000000000010101010100000000000000000000000101000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000
__map__
000000000000000000000000000000004f00000000000000000000000000004f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004f00000000000000000000000000004f000000000000000000000000000000000000000000000000000000000000000000000001710000001900007101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004f00000000000000000000000000004f000000000000000000000000000000000000000000000000000000000000000000000040400000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004f00000000000000000000000000004f000000000000000000000000000000000000000000000000000000000000000070010000000000000000000000000170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004f00000000000000000000000000004f000040404040000000000000000000000000000000000000000000000000000040400000000042000042000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004f00000000000000000000000000004f000040000000000000000000000000000000000000000000000000000000000000000000001740404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004f00000000000000000000000000004f000000000000000000000000000000000000000000000000000000000000170000001700004141414141410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004f00000000000000000000000000004f000000000000000000000000000000000000000000000000000000000040404000000119000000000000000019010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004f00000000000000000000000000004f000000000000000000000000000000000000000000000000000000000000000000004141000000000000000041410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000019000000001900000000004f00000000000000000000000000004f000000000000000000000000000000000000000000000000000000000000000000000000000000017119000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f00000065666800006566680000004f4f00000065666800006566680000004f000000000000000100000000000000000000000000000000000000000000000000000000000041414141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f0000006c6c6c00006c6c6c0000004f4f0000006c6c6c00006c6c6c0000004f000000006060604040400000000000000000000000000000000000000000000000000071000000000000000071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0042c801010101010101010101d842004f00000000000000000000000000004f000000180000000000000000000000000000000000000000000000000000000000004040400000190000004040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6566666666666667667879666667676865666666666666676678796666676768000000000000000000000000000000000000000000000000000000000000000040000000000000404000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6a6c6c6c6c6a6c69696c696c696c6c6c6a6c6c6c6c6a6c69696c696c696c6c6c42000000002e00000000000001000000012700280029002a002b002c002d012e70000001004200000000420001000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000404044404041414141404040404040404040404040404040404040404040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0014151516000001010000141515160000141515160000010100001415151600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c81b1c1c1d1e656667683f1b1c1c1dc8c81b1c1c1d1e656667683f1b1c1c1dc8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6568474846496c69696a4e46474865686568474846496c69696a4e4647486568000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6c4f50544f8e8f5758aeaf4f50544f6c6c4f50544f8e8f5758aeaf4f50544f6c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00595a5b5c9e9f5f63bebf645a5b640000595a5b5c9e9f5f63bebf645a5b6400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0065666666666667667879666667680000656666666666676678796666676800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0069696c6c6a6c69696c696c696c6c000069696c6c6a6c69696c696c696c6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1900010000000000000000000001001900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6566666768001900001900777978797a6566666768000000000000777978797a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6a69696b690077796768006d6969696e6a69696b690077796768006d6969696e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000006b6c69690000000000000000000000006b6c6969000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d80000010042737475764200010000d800000000000073747576000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68007778797a7b7c7d7e7f78787a007768007778797a7b7c7d7e7f78787a0077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6900696c696c000000006a696c69006d6900696c696c000000006a696c69006d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444444444444444444444444444444444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
01050000000000000000000000002f510305112e5100000030510000002e510005002a5102b5112b5122b51530510000002e51000000305100050029510000002a5102b5112b5122b5122951224512225111a511
01050000000000000000000000002f510305112e5100000030510000002e510005002a5102b5112b5122b51530510000002e51000000305100050033510000002f51030511305123051230512305122e51126511
01050000000000000000000000002f510305112e5100000030510000002e510005002a5102b5112b512265113251033511335123251131512325113251231511305103151131512315112f510305112b51125511
010600001307307033000000000013073070330000000600324151810400674000000c625000053e5140000024673186130000000000324150000000000000000c62500000325140000000674000000000000000
01060000130730703300000000000c6250000000000000003e41518104006740000013073070333251400000246731861300000000003e4150000000000000000c625000003e5140000000674000000000000000
010600200000000000000000000000000000000000000000000000000000000000000000000000000000000039c132dc150000000000000000000000000000000000000000000000000000000000000000000000
010600201531409321097500975015314093210975009760097600976009760097600976009760097600976039c132dc150973009730097300973009730097300972009720097200972009720097200972009720
010600001431408321087500875014314083210875008760087600876008760087600876008760087600876039c132dc150873008730087300873008730087300872008720087200872008720087200872008720
010600000e3140232102750027500e314023210275002760027600276002760027600276002760027600276039c132dc150273002730027300273002730027300272002720027200272002720027200272002720
010600001131405321057500575011314053210575005760057600576005760057600576005760057600576039c132dc150573005730057300573005730057300572005720057200572005720057200572005720
010600001331407321077500775013314073210775007760077600776007760077600776007760077600776039c132dc150773007730077300773007730077300772007720077200772007720077200772007720
01060000000000000000000000002d1050000000000184042d25521215000000000000000000000000000000343552831500000000002d215212150000000000374552b415000000000034315283150000000000
0106000030455244150000000000374152b41500000184042f35523315000000000030415244150000000000302552421500000000002f3152331500000000002d13521115000000000030215242150000000000
01060000000000000000000000002d105000000000018404284341c4050010000000000000000000000000003043424405000000000034414284050000000000344342b405000000000030414244050000000000
010600002d434214050000000000374142b40500000184042b4341f40500000000002d4142140500000000002d4342140500000000002b4141f4050000000000284241c40500000000002d414214050000000000
010600001e3530a033000000000013970148040000000000000000000013930000001e3530a03300000000000fc631663300000000000ff70000000fc13166130000000000000000000013970000000000000000
010600003cb500000000000000003cb100000000000000003cb500000000000000003cb100000000000000003cb500000000000000003cb10000003cb500000000000000003cb10000003cb50000000000000000
010600200e2550e0100e7100e7100e3550e0100e7100e71012455130110e7100e71015255150100e7100e71018455180100e7100e71018455180100e7100e71017255180110e7100e7101a4551a0100e7100e710
010600001d2551d0100e7100e7101a4551a0100e7100e71017455180110e7100e71015255150100e7100e71018455180100e7100e71015455150100e7100e71012255130110e7100e71015455150100e7100e710
010600001d2551d0100e7100e7101f4551f0100e7100e71020455210110e7100e7101f2551f0100e7100e7101d4551d0100e7100e7101a4551a0100e7100e71018255170110e7100e7101a4551a0100e7100e710
__music__
00 41050d44
00 41060c44
00 41050d44
00 41060c44
00 41050d44
00 41070c44
00 41050d44
00 41070c44
01 41050b11
00 41060c12
00 41050b13
00 41060c14
00 41050b1c
00 41070c19
00 41050b1d
00 41070c1a
00 41080e16
00 41090f17
00 41080e15
00 410a0f18
00 41080e16
00 41090f17
00 41080e15
00 410a101b
00 41050d1c
00 41060c44
00 41050d1d
00 41060c44
00 41050d1c
00 41060c1d
00 41050d1c
02 41060c1e
01 291f2227
00 2a202128
00 411f2144
00 41202144
00 291f2327
00 2a202128
00 411f2144
00 41202144
00 291f2427
00 2a202128
00 411f2144
00 41202144
00 291f2527
00 2a202128
00 291f2627
02 2a202128
01 412b2c2d
00 412b2c2e
00 412b2c2d
02 412b2c2f

