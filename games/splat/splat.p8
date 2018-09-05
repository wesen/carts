pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
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

local frame=0
local dt=0
local time_factor=1
local lasttime=time()
local room=nil

local actors={}
local tiles={}
local crs={}
local draw_crs={}

local player=nil
local enemy_manager=nil

local is_fading=false
local is_screen_dark=false

local dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,13}


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

cls_clock=class(function(self,pos)
 self.t=0
 self.pos=pos
end)

function cls_clock:update()
 self.t+=dt
end

function cls_clock:draw()
 for i=0,10 do
  local x=cos(self.t-i*0.1)
  local y=sin(self.t-i*0.1)
  darken(i*10)
  circfill(self.pos.x+x*10,self.pos.y+y*10,(10-i)/3,7)
 end
 pal()
end

local clock=cls_clock.init(v2(100,100))

local slow_time_factor=0.2
local slow_time_countdown=2

local state_normal_time=0
local state_slow_time=1

cls_clock_control=class(function(self)
 self.time_factor=1
 self.lasttime=time()
 self.countdown=0
 self.state=state_normal_time
end)

function cls_clock_control:get_dt()
 local dt=time()-lasttime
 self.countdown-=dt
 lasttime=time()
 if (self.state==state_slow_time) return dt*slow_time_factor
 return dt
end

function cls_clock_control:update()
 if self.state==state_slow_time and self.countdown<0 then
  self.state=state_normal_time
 end
end

function cls_clock_control:on_enemy_winds_up()
 self.state=state_slow_time
 self.countdown=slow_time_countdown
end

function cls_clock_control:on_enemy_attacks()
 self.state=state_normal_time
end

function cls_clock_control:on_player_attacks()
 self.state=state_slow_time
 self.countdown=slow_time_countdown
end

local clock_control=cls_clock_control.init()

cls_player=class(function(self,pos)
 self.pos=pos
end)

function cls_player:draw()
 rectfill(self.pos.x,self.pos.y,self.pos.x+8,self.pos.y+8,7)
end

function cls_player:update()
end

local countdown_idle=2
local countdown_winding_up=1
local countdown_attacking=1

local hit_interval=6

local state_idle=0
local state_winding_up=1
local state_attacking=2
local state_stunned=3
local enemy_colors={}
enemy_colors[state_idle]=7
enemy_colors[state_winding_up]=9
enemy_colors[state_attacking]=8
enemy_colors[state_stunned]=7

cls_enemy_manager=class(function(self)
 self.enemies={}
 self.hit_countdown=2
end)

function cls_enemy_manager:draw()
 foreach(self.enemies,function(e)
  rectfill(e.pos.x,e.pos.y,e.pos.x+8,e.pos.y+8,enemy_colors[e.state])
 end)
end

function cls_enemy_manager:update()
 self.hit_countdown-=dt

 local lowest_countdown=countdown_idle
 local next_enemy=nil

 foreach(self.enemies,function(e)
  e.countdown-=dt

  if e.state==state_idle and e.countdown<lowest_countdown then
   next_enemy=e
   lowest_countdown=e.countdown
  elseif e.state==state_winding_up and e.countdown<0 then
   printh("ATTACK")
   clock_control:on_enemy_attacks()
   e.state=state_attacking
   e.countdown=countdown_attacking
  elseif e.state==state_attacking and e.countdown<0 then
   e.state=state_idle
   e.countdown=countdown_idle
  end
 end)

 if self.hit_countdown<0 and next_enemy!=nil then
  self.hit_countdown=hit_interval
  next_enemy.state=state_winding_up
  next_enemy.countdown=countdown_winding_up
  clock_control:on_enemy_winds_up()
 end
end

function cls_enemy_manager:add_enemy(pos)
 add(self.enemies,{
  state=state_idle,
  pos=pos,
  countdown=0
})
end


function _init()
 player=cls_player.init(v2(64,64))
 enemy_manager=cls_enemy_manager.init()
 enemy_manager:add_enemy(v2(32,64))
 enemy_manager:add_enemy(v2(64,32))
 enemy_manager:add_enemy(v2(64,96))
 enemy_manager:add_enemy(v2(96,64))
end

function _draw()
 frame+=1

 cls()
 if not is_screen_dark then
 end

 tick_crs(draw_crs)
 foreach(actors, function(a) a:draw() end)
 enemy_manager:draw()
 player:draw()
 clock:draw()
end

function _update60()
 clock_control:update()
 dt=clock_control:get_dt()
 lasttime=time()
 tick_crs(crs)

 player:update()
 enemy_manager:update()
 foreach(actors, function(a) a:update() end)
 clock:update()
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
