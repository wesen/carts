pico-8 cartridge // http://www.pico-8.com
version 8
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
typ_exit=14
typ_game=15
typ_heart=16

flg_solid=0
flg_ice=1
flg_opaque=2

btn_right=1
btn_left=0
btn_jump=4
btn_action=5


function class (typ,init)
  local c = {}
  c.__index = c
  c._ctr=init
  c.typ=typ
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    self.typ=typ
    return self
  end
  return c
end

function subclass(typ,parent,init)
 local c=class(typ,init)
 return setmetatable(c,{__index=parent})
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


jump_button_grace_interval=10
jump_max_hold_time=15

ground_grace_interval=12

moth_los_limit=200

dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,13}

levels={
 -- level 1
 {pos=v2(0,0),
  dim=v2(16,16)},
 -- level 2
 {pos=v2(16,0),
  dim=v2(16,16)},
 -- level 3
 {pos=v2(32,0),
  dim=v2(16,16)},
 -- level 4
 {pos=v2(48,0),
  dim=v2(16,16)},
 -- level 5
 {pos=v2(64,0),
  dim=v2(16,16)},
 -- level 6
 {pos=v2(80,0),
  dim=v2(16,16)},
 -- level 9
 {pos=v2(0,16),
  dim=v2(16,16)},
 -- level 7
 {pos=v2(96,0),
  dim=v2(16,16)},
 -- level 8
 {pos=v2(112,0),
  dim=v2(16,16)},
 -- level 10
 {pos=v2(16,16),
  dim=v2(16,16)},
  -- {lamp_nr,countdown_s}
  -- countdown_lights={{1,4}},
  -- {lamp_nr,frames_off,frames_on}
  -- timer_lights={{2,128,64}}
}


frame=0
dt=0
lasttime=time()
room=nil

actors={}
tiles={}
crs={}
draw_crs={}

moth=nil
player=nil

is_fading=false
is_screen_dark=false

cls_camera=class(typ_camera,function(self)
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
 self.pos=room:bbox():shrink(64):clip(self.pos)
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

function should_blink(n)
 return flr(frame/n)%2==1
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

-- fade
function fade(fade_in)
 is_fading=true
 is_screen_dark=false
 local p=0
 for i=1,10 do
  local i_=i
  local time_elapsed=0

  if (fade_in==true) i_=10-i
  p=flr(mid(0,i_/10,1)*100)

  while time_elapsed<0.1 do
   darken(p,1)

   if not fade_in and p==100 then
    -- this needs to be set before the final yield
    -- draw will continue to be called even if we are
    -- in a coresumed cr, if i understand this correctly
    is_screen_dark=true
   end

   time_elapsed+=dt
   yield()
  end
 end

 is_fading=false
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
 self.new_light_debounce=0
 self.ghosts={}
 self.heart_hitbox=hitbox(v2(-3,-3),v2(8+6,8+6))
 self.heart_debounce=0
 del(actors,self)
 moth=self
end)

tiles[spr_moth]=cls_moth

function cls_moth:get_nearest_lamp()
 local nearest_lamp=nil
 local dir=nil
 local dist=10000
 for _,lamp in pairs(room.lamps) do
  if lamp.is_on then
   local v=(lamp.pos-self.pos)
   local d=v:magnitude()
   if d<dist and d<moth_los_limit then
    if self:is_lamp_visible(lamp) then
     dist=d
     dir=v
     nearest_lamp=lamp
    end
   end
  end
 end

 return nearest_lamp,dir
end

function cls_moth:is_lamp_visible(lamp)
 local ray=bbox(self.pos+v2(4,4),lamp.light_position)
 for tile in all(room.opaque_tiles) do
  local p=isect(ray,tile)
  if (#p>0) return false
 end
 return true
end

function cls_moth:update()
 self.new_light_debounce=max(0,self.new_light_debounce-1)

 if self.new_light_debounce==0 then
  local nearest_lamp=self:get_nearest_lamp()
  if nearest_lamp!=nil then
   local p=nearest_lamp.light_position
   if p!=self.target then
    self.new_light_debounce=60
    self.target=nearest_lamp.light_position
    self.found_lamp=true
   end
  elseif self.found_lamp then
   self.found_lamp=false
   self.target=self.pos:clone()
  end
 end

 local maxvel=.8
 local accel=0.05
 local dist=self.target-self.pos
 self.target_dist=dist:magnitude()

 local spd=v2(0,0)
 if self.target_dist>1 then
  spd=dist/self.target_dist*maxvel
 end
 self.spd.x=appr(self.spd.x,spd.x,accel)+mrnd(accel)
 self.spd.y=appr(self.spd.y,spd.y,accel)+mrnd(accel)

 if (abs(self.spd.x)>0.2) self.flip.x=self.spd.x<0
 self:move(self.spd)

 self.spr=spr_moth+flr(frame/8)%3

 if self.spd:sqrmagnitude()>0.1 and #self.ghosts<7 then
  if (frame%5==0) insert(self.ghosts,self.pos:clone())
 else
  popend(self.ghosts)
 end

 -- heart collision
 if player!=nil and self.heart_hitbox:to_bbox_at(self.pos):collide(player:bbox()) then
  if self.heart_debounce<=0 then
   cls_heart.init(self.pos)
   sfx(rnd_elt({41,42,43,44,45,46,47}))
   self.heart_debounce=48+rnd(32)
  else
   self.heart_debounce-=1
  end
 else
  self.heart_debounce=0
 end
end

function cls_moth:draw()
 local cols={6,6,13,13,5,1,1}
 for i,ghost in pairs(self.ghosts) do
  circfill(ghost.x+4,ghost.y+4,.5,cols[i])
 end

 bspr(self.spr,self.pos.x,self.pos.y,self.flip.x,self.flip.y,0)
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
cls_room=class(typ_room,function(self,r)
 self.pos=r.pos
 self.dim=r.dim
 self.player_spawn=nil
 self.moth_spawn=nil
 self.lamps={}
 self.switches={}
 self.opaque_tiles={}

 room=self

 -- initialize tiles
 for i=0,self.dim.x-1 do
  for j=0,self.dim.y-1 do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   -- add solid tile bboxes for collision check
   if fget(tile,flg_opaque) then
    add(self.opaque_tiles,bbox(p*8,p*8+v2(8,8)))
   end
   if (tile==spr_spawn_point) self.player_spawn=p*8
   if (tile==spr_moth) self.moth_spawn=p*8
   local t=tiles[tile]
   if (t!=nil) t.init(p*8,tile)
  end
 end

  -- configuring special lights from config
  local l=levels[game.current_level]
  for timer in all(l.timer_lights) do
   for lamp in all(self.lamps) do
    if lamp.nr==timer[1] then
     lamp.timer={timer[2],timer[3]}
    end
   end
  end

  for timer in all(l.countdown_lights) do
   for lamp in all(self.lamps) do
    if lamp.nr==timer[1] then
     lamp.countdown=timer[2]
    end
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
 palt(14,true)
 palt(0,false)
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
 palt()
end

function cls_room:spawn_player()
 local spawn=cls_spawn.init(self.player_spawn:clone())
 main_camera:set_target(spawn)
end

function cls_room:handle_switch_toggle(switch)
 self.player_spawn=switch.pos

 switch.is_on=not switch.is_on

 for lamp in all(self.lamps) do
  if lamp.nr==switch.nr then
   lamp:toggle()
  end
 end

 -- sync all the other switches on the same circuit
 for s_ in all(self.switches) do
  if (s_.nr==switch.nr) s_.is_on=switch.is_on
 end
 if switch.is_on then
  sfx(30)
 else
  sfx(31)
 end
end

-- this is a bit dirty because every lamp on the circuit will sync the switches
function cls_room:handle_lamp_off(lamp)
 lamp:toggle()
 for s_ in all(self.switches) do
  if (s_.nr==lamp.nr) s_.is_on=lamp.is_on
 end
 for l in all(self.lamps) do
  if (l.nr==lamp.nr and l!=lamp) l:toggle()
 end
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


cls_gore=subclass(typ_gore,cls_particle,function(self,pos)
 cls_particle._ctr(self,pos,0.5+rnd(2),{35,36,37,38,38})
 self.hitbox=hitbox(v2(2,2),v2(3,3))
 self.spd=angle2vec(rnd(0.5))
 self.spd.y*=1.5
 -- self:random_angle(1)
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
 local on_ground=solid_at(ground_bbox)
 local on_ceil=solid_at(ceil_bbox)
 local hit_side=solid_at(side_bbox)
 if on_ground then
  self.spd.y*=-0.9
 elseif on_ceil then
  self.spd.y*=-0.9
 elseif hit_side then
  self.spd.x*=-0.9
 end
end

function make_gore_explosion(pos)
 for i=0,30 do
  cls_gore.init(pos)
 end
end
cls_heart=subclass(typ_heart,cls_particle,function(self,pos)
 cls_particle._ctr(self,pos+v2(mrnd(3),-rnd(3)-2),2.5+rnd(2),{20})
 self.spd=v2(0,-rnd(0.3)-0.2)
 self.amp=0.6+rnd(0.4)
 self.offset=maybe() and 0 or 0.5
 self.angle_spd=rnd(.4)+0.3
 self.ghosts={}
end)

function cls_heart:update()
 self.spd.x=cos(self.t*self.angle_spd+self.offset)*self.amp
 cls_particle.update(self)

 if #self.ghosts<7 then
  if (frame%5==0) insert(self.ghosts,self.pos:clone())
 else
  popend(self.ghosts)
 end
end

function cls_heart:draw()
 cls_particle.draw(self)

 local cols={8,8,14,14,15,15,6,6,7}
 for i,ghost in pairs(self.ghosts) do
  circfill(ghost.x+4,ghost.y+4,.5,cols[i])
 end
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
 self.step_count=0

 self.ghosts={}
 self.on_ground=true

end)

function cls_player:smoke(spr,dir)
 return cls_smoke.init(self.pos,spr,dir)
end

function cls_player:kill()
 make_gore_explosion(self.pos)
 player=nil
 main_camera:add_shake(8)
 sfx(0)
 add_cr(function()
  wait_for(1)
  room:spawn_player()
 end)
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
 self.on_ground=on_ground
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
   self.step_count=0
   if on_ice then
    self:smoke(spr_ice_smoke,-input)
   else
    -- smoke when changing directions
    self:smoke(spr_ground_smoke,-input)
    sfx(34)
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

 -- compute x speed by acceleration / friction
 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel)
 else
  self.spd.x=appr(self.spd.x,0,decel)
 end

 if self.spd.x!=0 then
  -- step sounds
  if input != 0 and on_ground then
   self.step_count+=1
   if self.step_count==22 then
    sfx(36)
    self.step_count=0
   elseif self.step_count==15 then
    sfx(37)
   elseif self.step_count==7 then
    sfx(33)
   end
  end

  -- orient sprite
  self.flip.x=self.spd.x<0
 end

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
    sfx(35)
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
    sfx(35)
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

 if (not on_ground and frame%2==0) insert(self.ghosts,self.pos:clone())
 if ((on_ground or #self.ghosts>7)) popend(self.ghosts)
end

function cls_player:draw()
 local dark=0
 for ghost in all(self.ghosts) do
  dark+=10
  darken(dark)
  spr(self.spr,ghost.x,ghost.y,1,1,self.flip.x,self.flip.y)
 end
 pal()

 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)

 -- not convinced by border
 -- bspr(self.spr,self.pos.x,self.pos.y,self.flip.x,self.flip.y,0)

 -- debug drawing bbox
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
    sfx(38)
    main_camera:add_shake(3)
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
  cr_move_to(self,self.target,1,inexpo)
  del(actors,self)
  cls_player.init(self.target)
  cls_smoke.init(self.pos,spr_full_smoke,0)
  sfx(32)
 end)
 add_cr(function()
  wait_for(1.1)
  main_camera:add_shake(8)
 end)
end)

function cls_spawn:cr_spawn()
end

function cls_spawn:draw()
 spr(spr_spawn_point,self.pos.x,self.pos.y)
end
spr_spikes=68
spr_spikes_v=71

cls_spikes=subclass(typ_spikes,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.spr=tile
 if tile==spr_spikes then
  self.hitbox=hitbox(v2(0,3),v2(8,5))
 else
  self.hitbox=hitbox(v2(0,0),v2(8,5))
 end
end)
tiles[spr_spikes]=cls_spikes
tiles[spr_spikes_v]=cls_spikes

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
 spr(self.spr,self.pos.x,self.pos.y)
 -- local bbox=self:bbox()
 -- local bbox_col=8
 -- bbox:draw(bbox_col)
end
cls_moving_platform=subclass(typ_moving_platform,cls_actor,function(pos)
 cls_actor._ctr(self,pos)
end)
spr_lamp_off=98
spr_lamp_on=96
spr_lamp2_off=106
spr_lamp2_on=104

spr_lamp_nr_base=84

cls_lamp=subclass(typ_lamp,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.is_on=(tile)%4==0
 self.is_solid=false
 -- lookup number in tile below
 self.nr=room:tile_at(self.pos/8+v2(0,1))-spr_lamp_nr_base
 self.spr=tile-(self.is_on and 0 or 2)
 self.light_position=self.pos+v2(6,6)
 add(room.lamps,self)
end)

tiles[spr_lamp_off]=cls_lamp
tiles[spr_lamp_on]=cls_lamp
tiles[spr_lamp2_off]=cls_lamp
tiles[spr_lamp2_on]=cls_lamp

function cls_lamp:update()

 -- flickering light logic
 if self.timer!=nil then
  local tick=frame%self.timer[1]
  if tick==0 or tick==self.timer[2] then
   self.is_on=not self.is_on
   if (self.is_on) sfx(40)
  end
 end

 -- these lights turn off after a while
 if self.countdown!=nil and self.is_on then
  self.countdown_t-=dt
  if self.countdown_t<0 then
   room:handle_lamp_off(self)
   sfx(31)
  end
 end
end

function cls_lamp:toggle()
 self.is_on=not self.is_on
 if self.countdown!=nil and self.is_on then
  self.countdown_t=self.countdown
 end
end

function cls_lamp:draw()
 local is_light=self.is_on
 if (self.timer and maybe(0.01)) is_light=true

 if self.countdown_t!=nil
    and self.countdown_t<3
    and self.is_on then
  local max_blk=64
  local min_blk=16
  local h=max_blk-min_blk
  local blk=min_blk+(self.countdown_t/self.countdown)*h
  if should_blink(blk,blk) then
   is_light=false
  end
 end

 if not is_light then
  pal(9,0)
  pal(7,0)
 elseif is_light and not self.is_on then
  pal(13,1)
  pal(5,1)
  pal(6,1)
  pal(7,13)
 end
 local spr_=self.spr+(is_light and 0 or 2)
 spr(spr_,self.pos.x,self.pos.y,2,2)
 pal()

 if self.countdown_t!=nil and self.countdown_t>0 and is_light then
  local x1=self.pos.x
  local y1=self.pos.y-5
  rect(x1,y1,x1+10,y1+2,1)
  rect(x1+9*(1-self.countdown_t/self.countdown),y1+1,x1+9,y1+1,9)
 end
end

spr_switch_on=69
spr_switch_off=70

cls_lamp_switch=subclass(typ_lamp_switch,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.hitbox=hitbox(v2(-2,-2),v2(12,12))
 self.is_solid=false

 -- lookup number in tile above
 self.nr=room:tile_at(self.pos/8+v2(0,-1))-spr_lamp_nr_base
 self.is_on=tile==spr_switch_on
 self.player_near=false
 add(room.switches,self)
end)

tiles[spr_switch_off]=cls_lamp_switch
tiles[spr_switch_on]=cls_lamp_switch

function cls_lamp_switch:update()
 self.player_near=player!=nil and player:collides_with(self)
 if self.player_near and btnp(btn_action) then
  room:handle_switch_toggle(self)
 end
end

function cls_lamp_switch:draw()
 local spr_=self.is_on and spr_switch_on or spr_switch_off
 spr(spr_,self.pos.x,self.pos.y)
 -- self:bbox():draw(7)
end

function cls_lamp_switch:draw_text()
 if player!=nil and self.player_near and should_blink(24) and player.on_ground then
  palt(0,false)
  bstr("\x97",self.pos.x-1,self.pos.y-8,0,6)
  palt()
 end
end
spr_exit_on=100
spr_exit_off=102

cls_exit=subclass(typ_exit,cls_lamp,function(self,pos,tile)
 cls_lamp._ctr(self,pos,tile)
 self.hitbox=hitbox(v2(4,4),v2(8,8))
 self.player_near=false
 self.moth_near=false
 self.activated=false
end)

tiles[spr_exit_off]=cls_exit
tiles[spr_exit_on]=cls_exit

function cls_exit:update()
 self.player_near=player!=nil and player:collides_with(self)

 self.moth_near=moth!=nil and moth:collides_with(self)
 if self.moth_near and not self.activated then
  self.activated=true
  game:next_level()
 end
end

function cls_exit:draw()
 local spr_=self.is_on and spr_exit_on or spr_exit_off
 local blink=should_blink(24)
 if (should_blink(12) or maybe(.1)) pal(8,0)
 palt(0,false)
 spr(spr_,self.pos.x,self.pos.y,2,2)
 palt()
 pal()
end

cls_game=class(typ_game,function(self)
 self.current_level=1
end)

function cls_game:load_level(level,skip_fade)
 add_draw_cr(function ()
  if not skip_fade then
   fade(false)
   wait_for(1)
  end
  self.current_level=level
  actors={}
  player=nil
  moth=nil
  local l=levels[self.current_level]
  cls_room.init(l)

  fireflies_init(room.dim)
  room:spawn_player()
  fade(true)
  music(0)
  end)
end

function cls_game:next_level()
 music(-1,300)
 sfx(39)
 self:load_level(self.current_level%#levels+1)
end

game=cls_game.init()
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
-- x ray collision with moth to find nearest visible lamp
-- x switches can toggle multiple lamps
-- x exit door
-- x better help texts
-- x draw moth above light
-- x show tutorial text above switch
-- x make wider levels
-- x implement camera
-- x better darker tiles
-- x add fireflies flying around
-- x parallax background
-- x make fireflies slower
-- x better spreading of fireflies
-- x debounce moth switching lamps
-- x limit moth fov
-- x switch levels when reaching exit door
-- x readd gore on death

-- x respawn at last switch
-- x fade and room transitions

-- x add timed lamps
-- x hair after jump
-- x room transition sfx

-- x make timer lamps flicker
-- x add vertical spikes

-- x lamp off sfx
-- x lamp flicker sfx

-- x camera shake on death

-- x implement windows

-- add heart

-- make longer music
-- moth animation when seeing light

-- x make countdown lamps
-- x show progress bar on countdown lamp

-- x add simple intro levels

-- -x- better spike collision
-- -x- fix slight double jump (?)

-- add title screen

-- moth dash mechanics?

-- x-x-x generate parallax background
-- find a proper way to define lamp target offsets
-- x better lamp switches
-- x better moth movement
-- bresenham dashed line
-- x add checkpoints
-- x particles trailing moth

-- add fire as a moth obstacle

-- add frogs

-- enemies
-- moving platforms
-- laser beam
-- vanishing platforms

-- fades

-- music
-- sfx

--include main-test
--include main-test-oo
main_camera=cls_camera.init()

function _init()
 game:load_level(1,true)
end

local text_col=0

function _draw()
 frame+=1

 cls()
 if not is_screen_dark then
  local p=main_camera:compute_position()
  camera(p.x/1.5,p.y/1.5)
  fireflies_draw()

  camera(p.x,p.y)
  if (room!=nil) room:draw()
  draw_actors()
  if (player!=nil) player:draw()
  if (moth!=nil) moth:draw()

  palt(0,false)
  for a in all(actors) do
   if (a.draw_text!=nil) a:draw_text()
  end
  palt()

  camera(0,0)
  -- print cpu
  -- print(tostr(stat(1)),64,64,1)
  -- print(tostr(stat(7)).." fps",64,70,1)
 end

 tick_crs(draw_crs)

 if game.current_level==1 or game.current_level==10 then
  sspr(66,2,43,11,21,21,86,22)
  local fidx=flr(frame/8)%3*8
  sspr(8+fidx,0,8,8,2,24,16,16)
  sspr(40+fidx,0,8,8,110,25,16,16)
  print("- slono -",48,46,15)
 end

 if game.current_level==1 then
  local cols={6,6,13,13,5,5,1,1,5,5,13,13}
  print("guide bepo to the exit", 20, 58, cols[text_col+1])
  print("c - jump", 51, 66, cols[text_col+1])
  if (frame%4==0) text_col=(text_col+1)%#cols
 end
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
 fireflies_update()
 if (player!=nil) player:update()
 if (moth!=nil) moth:update()
 update_actors()
 main_camera:update()
end


__gfx__
0000000000ddd0000000000000ddd00000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddfdf0000ddd0000ddfdf000ddfdf000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700ddf1f1f00ddfdf00ddf1f1f0ddf1f1f000d00d000d0000d0000000000088008808800080008880808088008080080088808080000000000000000000
000770000ff1f1f0ddf1f1f00ff1f1f00ff1f1f00005500000d00d000dd00dd00090909009090909000900909090009990909009009090000000000000000000
0007700000ffff000ff1f1f000ffff0000ffff000058d8000558d8000555500000f0f0f00f0f0f0f000f00f0f0f000fff0f0f00f00f0f0000000000000000000
007007000009900000ffff0000044000000999600500d0000000d0000008d8000070707007070707000700707070007070707007007070000000000000000000
000000000004400000044000006006000004460000000000000000000000d0000077007707700707000700777077007070707007007770000000000000000000
00000000000660000006060000000000000000000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
000000000ff0ff0000000000f000f000000000000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
0990009900f00f0000f00f000fff0000008080000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
0095959000ffff0000ffff000cfc00000888780000000000000000000000000000f0f0f00f000f0f000f00f0f0f000f0f0f0f00f00f0f0000000000000000000
0009990000fcfc00f0fcfc0066e6600008e888000000000000000000000000000090909009000909000900909090009090909009009090000000000000000000
0009e900f0ffffe0f0fffef00f6f00f0008e80000000000000000000000000000088008808000080000800808088008080080008008080000000000000000000
00000009f0099000f0044f000fff00f0000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
65d6d656c776cc7c000000000000000000000000000000000000000085d88585cc6dc55dd55cd6ccc776cc7cc7cc677c00000000000000000000000000000000
006dd5007c5c566c00000000000000000000000000000000000000008dd0dd8076060d5dd5d060677c5c566cc665c5c700000000000000000000000000000000
d55655600c0c0c06000000000000000000000000006665000066650008000600c6cc00055000cc6c0c0c0c0660c0c0c000000000000000000000000000000000
5005566d500c5c6d6d0000000000000000000000006b65000068650008000800c50506d00d60505c500c5c6dd6c5c00500000000000000000000000000000000
005d000d005d000c0d6666500000000008000800006b650000686500000000006cccd50dd05dccc6005d000cc000d50000000000000000000000000000000000
000560d5555560d5d5d00d0000000000080006000065650000656500000000007500556dd6550057d65500577500556d00000000000000000000000000000000
5600d0555660d055550dd000056666508dd0dd80006d6500006d6500000000007cc0056556500cc756500cc77cc0056500000000000000000000000000000000
050005dd05dd05ddddd00d0000aaaa0085d88585006665000066650000000000c70505500550507c0550507cc705055000000000000000000000000000000000
cc6cc6cccc0000cc888ee88888eee88800eeee000000e00000eeee000eeeeee00000e00000eeeee0000eee000000000000000000000000000000000000000000
c6cc6ccccc0000cc00822000008888220e0000e0000ee00000e000e000000e00000e0e0000e0000000ee00000000000000000000000000000000000000000000
000000006c00006c0000000000028200e000000e00e0e00000e000e00000e00000e00e0000e000000e0000000000000000000000000000000000000000000000
00000000c60000c60000000000000000e000000e0000e000000000e00eeeee000e000e0000eeee00e00000000000000000000000000000000000000000000000
00000000cc0000cc0000000000000000e000000e0000e00000eeeee0000000e0e0000e0000000ee0eeeeeee00000000000000000000000000000000000000000
000000006c00006c0000000000000000e000000e0000e00000e00000000000e00eeeeeee000000e0e000000e0000000000000000000000000000000000000000
cc6cc6ccc60000c600000000000000000e0000e00000e00000e00000000000e000000e0000000ee00e00000e0000000000000000000000000000000000000000
c6cc6ccccc0000cc000000000000000000eeee0000eeeee000eeeee00eeeee0000000e0000eeee0000eeeee00000000000000000000000000000000000000000
00000000000000000000000000000000000000888800000000000088880000000000050000000000000005000000000000000000000000000000000000000000
000000000000000000000000000000000000008888000000000000888800000000000d000000000000000d000000000000000000000000000000000000000000
00000005d000000000000006d0000000000000000000000000000000000000000000060000000000000006000000000000000000000000000000000000000000
0000005005000000000000600600000000000d6666d0000000000d6666d0000000006d500000000000006d500000000000000000000000000000000000000000
000005d50d000000000006d50d000000000000555500000000000055550000000000999000000000000099900000000000000000000000000000000000000000
0000099905000000000009990d000000000000799700000000000000000000000000797000000000000009000000000000000000000000000000000000000000
000007970d000000000000900d000000000007777770000000000000000000000007777700000000000000000000000000000000000000000000000000000000
0000777776000000000000000d000000000007944970000000000076670000000057777750000000000000000000000000000000000000000000000000000000
00007777760000000000000005000000000079151597000000000755557000000577777775000000000000000000000000000000000000000000000000000000
0007777776000000000000000d000000000074515147000000000650056000005677777776500000000000000000000000000000000000000000000000000000
0007777776000000000000000d000000000774151547700000000650056000007777777777600000000000000000000000000000000000000000000000000000
0077777776700000000000000d000000000774515147700000000650056000007777777777700000000000000000000000000000000000000000000000000000
00777777767000000000000005000000007774151547770000000650056000007777777777700000000000000000000000000000000000000000000000000000
0777777776770000000000000d000000007774515147770000000650056000007777777777700000000000000000000000000000000000000000000000000000
077777776d570000000000006d500000077779151597777000000d5005d000005777777777500000000000000000000000000000000000000000000000000000
77777776d555700000000006d5550000077774515147777000000650056000000556666655000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007707700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005070000040000040707070700000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000550000000000000000000000000000000000000000000000000000560000000000000000000000000000000000000000000000000000000000560000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004600000000000000000000000000000000000000000057000000004600000000000000000040400000005800000000000000000000000000004600006a6b00006667000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040444440404040404040000000000000560000000000000000004600000000400000404000000057004747000000460000000000000000000000000040400000597b00005a77000044444000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000404040406a6b000000005666670000004600000000000000000040000000004000000000000000460000000000404000000000000000000000000000000000000000404040404000404000005a0043
0000000000000000000000000000000000000058000000000000000000000000000000000058000000000000000000000040000040557b00000000465677000044400000404000004044444444440000400000000000004040406a6b00006a6b0000000000000000570000000000000000000040006263005940000000460040
000000000000000000000000000000000000004600000057000000000000000000005500004600000000000056000000004000000000004040404040404040404040000040000000404040404040000040000000000000000000567b4300577b0000000000000000460000000000000000000040005873004640440044404440
0000000000000000000000000000000000004040400000460000000000000000000046004040444444400000460000000040440000000040000000000000000000400000400000000000006a6b006667400043000000000000000000404000004000000040400000404000000000000000000040505050505050500040404040
000000000000000000000000000000000000000000000040000000000000000000004000004040404040444440000000004040004000004000000000000000000040000000000058000000567b00577740444040000000550062630000006667400000006263590000006061000000430000000000000000006a000058474740
00000000000000000000000000000000000000000000000000004000000056000000000000000000004040404000444400544000400000400000000000000000004000000000004600000000000040404040006a6b000046005573000000587740000000597346000000597100000040000000000000000000566b4346000040
000000000000000000000000000000000000000000000000000000000000460044444444404000000000000000004040004600004000004000000000000000000040444440444440406a6b0000000040000000547b000040444440404040404040000040505050505050505040444440505050505040404000007b4040550040
000000000000000000000000000000000000000000000000006263550000404040404040400000000000666757006a6b40404040400000400000000000000000004040404040404000587b40400000400000000000000040404040000000000040000000000000000000000040404040006a6b00000000000000000000460040
00000000000000000000000000000000000000626354000000557346000062630000000062630040400057774600567b0000000040000040000000000000000000000000000000000000000000000040000000004000004000000000000000004000000000000000000000000000000005557b00000000000000544040400040
0000000000000000000000000000000000000054734600000040404000005673000000005473000040404040400000000000000040000040000000000000000000000000000000000000000000000040000000004000004000000000000000004040000051000040404040404040404000010000000000000000464056000040
0000000005000054000000000066670005000040404000000040666762634040050000000040005462630000006263000500000000626340000000000000000000050000006263540000404000004040050000004054004000000000000000000500540051006263006a6b006667000040400000006263000040404046004340
000100000000004600000000005477000001000000000000004058775773000000010000004000465573000000587300000100000054734000000000000000000000010000547346000000000000000000010043404600400000000000000000000146005100547300567b005777000000000000405473000000004040004040
4040404040404040404040404040404040404040404040404040404040404040404040404440404040404040404040404040404040404040000000000000000040404044444040404444444444444444404040404040404000000000000000004040404040404040404040404040404044444444404040404444444444444440
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000056000000000054000000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000046000000000046000000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040004441444441444400480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040004040404040404000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00414a0000006a00006667570000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040005600005777460000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040000000404040400000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000540040000000000000000000004800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000460062630000000000000055004b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444404354730000004b44440046000000000000000000000000000000546667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
404040404040000000404049004b444400000000000000000000000000465477000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000490048404000000000000000000000000000404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000500540000006263000048000000000000000000050000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000460000005573000048000000000000000000010000000043400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040414141414444444141414141000040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009
__sfx__
010100001504024050220501d0501e0501d0501c0501b0501a050180501705016050140501405014050130501205014050100500f0500e0500c0400b040090300803008030060200602006010060100000000000
011800200c0350f035130350c0351f0351a0351b0351f0350c0300c0250c01500000000000000000000000000e03511035140350e035110351b03518035110351403014025140151400000000000000000000000
001800001802018020180200c0200c7200c7201b0201b0201b0201b0201b02511020117201172511020110200e0200e0200e0200e0200e7200e7200e0200f0200f0200f0200f0251302013720137251302013020
011800002b0322b0322b0222b0222b1122b1122903229032290222902229012290122901229012291122911227032270222702227012271122612226032260222602226012261122412224022240222b1222b122
011800001d03513035160350f035220351d0351f0350c0350e0300e015130051d005000000000000000000001103514035110350e0351a0351b0351a035160351303013015000000000000000000000000000000
011800002c0322c0322c0222c0222c1122c1122b0322b0322b0222b0222b02229022290222901226112261122703227022270222701227112241222403224022240221b0121b1121b1221b0221a0221a1121a112
001800001102011020110200c0200c7200c7200c0201402014020140201802518020187201b7251b0201a0200e0200e0200e0200e0200e7200e7200e0200f0200f0200f0200f0251302013720137251302013020
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000000001105416750187501b7501d7501f750220502205027050290502e02027020290152b0002e00030000330003500035000000000000000000000000000000000000000000000000000000000000000
0104000029054277522e752297522775222752227521f0521d0521b05218042160321101515000290002b0002e00030000330001e000350000000000000000000000000000000000000000000000000000000000
01030000000000505006050060500705008050090500a0500c0500d0500f05011050170501c05023050290502d050000000000000000000000000000000000000000000000000000000000000000000000000000
010400000f255333000a3000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000f6550f6000f6000f60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000f6500f655160451d045270352e0350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000013265333000a3000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000c255333000a3000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c0500805008050000000b0500b0500c0500e0500f0501105016050180501b0501f05022050240502405022050200501d0501b0501605016050160501b0501d0501f0501d0501b0501b0500000000000
010c00000c0350f035130351b0351f03524035270352b0353004030032300223001230015000000e00011000140000e000110001b000180001100014000140001400014000000000000000000000000000000000
010c00002452024522245250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800002b0322b0222b0122b01500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800001803218022180121801500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800002703227022270122701500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800001b0321b0221b0121b01500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800001f0321f0221f0121f01500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800002403224032240122401500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800002203222022220122201500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01424344
00 04464544
00 01024344
00 04064544
00 01020344
00 04060544
00 01020344
00 04060544
00 41020344
00 44060544
00 01020344
00 04060544
00 01020344
00 04060544
00 01420344
02 04460544

