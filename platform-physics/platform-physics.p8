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

cls_debouncer=class(function(self,duration)
 self.duration=duration
 self.t=0
end)

function cls_debouncer:debounce(v)
 if v then
  self.t=self.duration
 elseif self.t>0 then
  self.t-=1
 end
end

function cls_debouncer:is_on()
 return self.t>0
end

function cls_debouncer:clear()
 self.t=0
end

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

-- queues - *sigh*
function popend(t)
 t[#t]=nil
end

function insert(t,val,max_)
 local l=min(#t+1,max_)
 for i=l,2,-1 do
  t[i]=t[i-1]
 end
 t[1]=val
end

local maxfall=2
local wallslide_maxfall=0.4
local wallslide_ice_maxfall=1

local gravity=0.12

local ground_grace_interval=12

local maxrun=1

local accel=0.3
local decel=0.2
local air_accel=0.2
local air_decel=0.1
local ice_accel=0.1
local ice_decel=0.03

local jump_spd=.2

local jump_button_grace_interval=10
local jump_max_hold_time=15

cls_button=class(function(self,btn_nr)
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

cls_logger=class(function(self,duration)
 self.values={}
 self.duration=duration
end)

function cls_logger:add(key,val)
 if (self.values[key]==nil) self.values[key]={}
 local l=self.values[key]
 insert(l,val,128)
end

function cls_logger:draw(key,min,max,col)
 local l=self.values[key]
 local range=max-min
 if l!=nil then
  for i=#l,1,-1 do
   local v=l[i]
   local y=64+64*(v-min)/range
   pset(128-i,y,col)
  end
 end
end

flg_solid=0
flg_ice=1

btn_right=1
btn_left=0
btn_jump=4
btn_action=5

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

cls_menu=class(function(self)
 self.entries={}
 self.current_entry=1
 self.visible=true
end)

function cls_menu:draw()
 local h=8 -- border
 for entry in all(self.entries) do
  h+=entry:size()
 end

 local w=64
 local left=64-w/2
 local top=64-h/2
 rectfill(left,top,64+w/2,64+h/2,5)
 rect(left,top,64+w/2,64+h/2,7)
 top+=6
 local y=top
 for i,entry in pairs(self.entries) do
  local off=0
  if i==self.current_entry then
   off+=1
   spr(22,left+3,y-2)
  end
  entry:draw(left+10+off,y)
  y+=entry:size()
 end
end

function cls_menu:add(text,cb)
 add(self.entries,cls_menuentry.init(text,cb))
end

function cls_menu:update()
 local e=self.current_entry
 local n=#self.entries
 self.current_entry=btnp(3) and tidx_inc(e,n) or (btnp(2) and tidx_dec(e,n)) or e

 if (btnp(5)) self.entries[self.current_entry]:activate()
 self.entries[self.current_entry]:update()
end

cls_menuentry=class(function(self,text,callback)
 self.text=text
 self.callback=callback
end)

function cls_menuentry:draw(x,y)
 print(self.text,x,y,7)
end

function cls_menuentry:size()
 return 8
end

function cls_menuentry:activate()
 if (self.callback!=nil) self.callback(self)
end

function cls_menuentry:update()
end

cls_menu_numberentry=class(function(self,text,callback,value,min,max,inc)
 self.text=text
 self.callback=callback
 self.value=value
 self.min=min or 0
 self.max=max or 10
 self.inc=inc or 1
 self.state=0 -- 0=close, 1=open
 if (self.callback!=nil) self.callback(self.value,self)
end)

function cls_menu_numberentry:size()
 return self.state==0 and 8 or 18
end

function cls_menu_numberentry:activate()
 if self.state==0 then
  self.state=1
 else
  self.state=0
 end
end

function cls_menu_numberentry:draw(x,y)
 if self.state==0 then
  print(self.text,x,y,7)
 else
  print(self.text,x,y,7)
  local off=10
  local w=24
  local left=x
  local right=x+w
  line(left,y+off,right,y+off,13)
  line(left,y+off,left,y+off+1)
  line(right,y+off,right,y+off+1)
  line(left+1,y+off+2,right-1,y+off+2,6)
  local pct=(self.value-self.min)/(self.max-self.min)
  print(tostr(self.value),right+5,y+off-2,7)
  spr(21,left-2+pct*w,y+off-2)
 end
end

function cls_menu_numberentry:update()
 if (btnp(0)) self.value=max(self.min,self.value-self.inc)
 if (btnp(1)) self.value=min(self.max,self.value+self.inc)
 if (self.callback!=nil) self.callback(self.value)
end

function tidx_inc(idx,n)
 return (idx%n)+1
end

function tidx_dec(idx,n)
 return (idx-2)%n+1
end

-- implement bounded acceleration
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

spr_wall_smoke=54
spr_ground_smoke=51
spr_full_smoke=48
spr_ice_smoke=57
spr_slide_smoke=60

cls_smoke=class(function(self,pos,start_spr,dir)
 self.pos=pos+v2(mrnd(1),0)
 self.flip=v2(maybe(),false)
 self.spr=start_spr
 self.start_spr=start_spr
 self.is_solid=false
 self.spd=v2(dir*(0.3+rnd(0.2)),-0.0)
 add(actors,self)
end)

function cls_smoke:update()
 self.pos+=self.spd
 self.spr+=0.2
 if (self.spr>self.start_spr+3) del(actors,self)
end

function cls_smoke:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

flg_solid=0

cls_room=class(function(self)
 self.pos=v2(0,0)
 self.dim=v2(16,16)
end)

function cls_room:bbox()
 return bbox(v2(0,0),self.dim*8)
end

function cls_room:draw()
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
end

function cls_room:tile_at(pos)
 local v=self.pos+pos
 return mget(v.x,v.y)
end

function cls_room:solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>self.dim.x*8
  or bbox.aa.y<0
  or bbox.bb.y>self.dim.y*8 then
   return true,nil
 else
  return self:tile_flag_at(bbox,flg_solid)
 end
end

function cls_room:tile_flag_at(bbox,flag)
 local bb=bbox:to_tile_bbox()
 for i=bb.aa.x,bb.bb.x do
  for j=bb.aa.y,bb.bb.y do
   local v=v2(i,j)
   local v2=v+self.pos
   if fget(mget(v2.x,v2.y),flag) then
    return true,v
   end
  end
 end
 return false
end

cls_player=class(function(self)
 self.pos=v2(64,16)
 self.spd=v2(0,0)
 self.spr=1
 self.flip=v2(false,false)

 self.hitbox=hitbox(v2(2,0),v2(4,8))
 self.jump_button=cls_button.init(btn_jump)
 self.on_ground=true
 self.ground_debouncer=cls_debouncer.init(ground_grace_interval)
 self.prev_input=0

 self.ghosts={}
end)

function cls_player:str()
 return "player["..tostr(self.id)..",t:"..tostr(self.typ).."]"
end

function cls_player:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return self.hitbox:to_bbox_at(self.pos+offset)
end

function cls_player:is_solid_at(offset)
 return room:solid_at(self:bbox(offset))
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
end

function cls_player:smoke(spr,dir)
 return cls_smoke.init(self.pos,spr,dir)
end

function cls_player:update()
 self.jump_button:update()

 -- get arrow input
 local input=btn(btn_right) and 1
    or (btn(btn_left) and -1
    or 0)
 if (menu.visible) input=0

 -- check if we are on ground
 local bbox_ground=self:bbox(vec_down)
 local bbox_dir=self:bbox(v2(input,0))
 local on_ground,tile=room:solid_at(bbox_ground)
 self.on_ground=on_ground
 self.ground_debouncer:debounce(on_ground)
 local on_ground_recently=self.ground_debouncer:is_on()
 local on_ice=room:tile_flag_at(bbox_ground,flg_ice)

 -- compute x speed by acceleration / friction
 local accel_=accel
 local decel_=decel
 local maxfall_=maxfall

 if not on_ground then
  accel_=air_accel
  decel_=air_decel
 end

 if on_ice then
  accel_=ice_accel
  decel_=ice_decel
 end

 -- slow down at apex
 local gravity_=gravity
 if abs(self.spd.y)<=0.3 then
  gravity_*=0.5
 elseif self.spd.y>0 then
  -- fall down fas2er
  gravity_*=2
 end

 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel_)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel_)
 else
  self.spd.x=appr(self.spd.x,0,decel_)
 end

 if self.spd.x!=0 then
  self.flip.x=self.spd.x<0
 end

 -- wall slide
 local is_wall_sliding=false
 if input!=0 and room:solid_at(bbox_dir) and not on_ground and self.spd.y>0 then
  is_wall_sliding=true
  maxfall_=wallslide_maxfall
  if (room:tile_flag_at(bbox_dir,flg_ice)) maxfall_=wallslide_ice_maxfall
  local smoke_dir = self.flip.x and .3 or -.3
  if maybe(.1) then
    local smoke=self:smoke(spr_wall_smoke,smoke_dir)
    smoke.flip.x=self.flip.x
  end
 end

 -- compute Y speed
 if self.jump_button.is_down then
  if self.jump_button:is_held() or
  (self.jump_button:was_recently_pressed() and on_ground_recently) then
   if (self.jump_button:was_recently_pressed()) self:smoke(spr_ground_smoke,0)
    self.spd.y=-jump_spd
    self.ground_debouncer:clear()
    self.jump_button.hold_time+=1
   elseif self.jump_button:was_just_pressed() then
    local wall_dir=self:is_solid_at(v2(-3,0)) and -1
         or self:is_solid_at(v2(3,0)) and 1
         or 0
    if wall_dir!=0 then
     self.spd.y=-jump_spd
     self.spd.x=-wall_dir*(maxrun+1)
     self:smoke(spr_wall_smoke,-wall_dir*.3)
     self.jump_button.hold_time+=1
   end
  end
 end
 if (not on_ground) self.spd.y=appr(self.spd.y,maxfall_,gravity_)

 -- actually move
 self:move_x(self.spd.x)
 self:move_y(self.spd.y)

 -- log values
 logger:add("spd.x",self.spd.x)
 logger:add("spd.y",self.spd.y)
 logger:add("pos.x",self.pos.x)
 logger:add("pos.y",self.pos.y)

 -- compute graphics
 if input!=self.prev_input and input!=0 and on_ground then
  if on_ice then
   self:smoke(spr_ice_smoke,-input)
  else
   -- smoke when changing directions
   self:smoke(spr_ground_smoke,-input)
  end
 end

  -- add ice smoke when sliding on ice (after releasing input)
 if on_ice and input==0 and abs(self.spd.x)>0.3
    and (maybe(0.15) or self.prev_input!=0) then
   self:smoke(spr_slide_smoke,-input)
 end

 self.prev_input=input

 -- choosing sprite
 if input==0 then
  self.spr=1
 elseif is_wall_sliding then
  self.spr=4
 elseif not on_ground then
  self.spr=3
 else
  self.spr=1+flr(frame/4)%3
 end

 if (not on_ground and frame%2==0) insert(self.ghosts,self.pos:clone(),7)
 if ((on_ground or #self.ghosts>7)) popend(self.ghosts)
end

function cls_player:move_x(amount)
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
end

function cls_player:move_y(amount)
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
end


actors={}

logger=cls_logger.init(128)
menu=cls_menu.init()
local player=cls_player:init()
room=cls_room:init()
frame=0
dt=0
local lasttime=time()
local show_x=false
local show_y=true

function _init()
 menu.visible=false

 menu:add("hide y",
  function(self)
    if show_y then
     show_y=false
     self.text="show y"
    else
     show_y=true
     self.text="hide y"
   end
  end)
 menu:add("show x",
  function(self)
    if show_x then
     show_x=false
     self.text="show x"
    else
     show_x=true
     self.text="hide x"
   end
  end)
 local e=cls_menu_numberentry.init("gravity",function(v) gravity=v end,0.12,0,0.3,0.05)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("accel",function(v) accel=v end,0.3,0,1,0.05)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("decel",function(v) decel=v end,0.2,0,1,0.05)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("maxrun",function(v) maxrun=v end,1,0,3,0.1)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("jump_spd",function(v) jump_spd=v end,1,0,2,0.05)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("air_accel",function(v) air_accel=v end,0.2,0,.4,0.01)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("air_decel",function(v) air_decel=v end,0.1,0,.4,0.01)
 add(menu.entries,e)
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 if ((btnp(3) and btn(2)) or (btn(3) and btnp(2)))  menu.visible=not menu.visible

 if (menu.visible) menu:update()
 player:update()
 for actor in all(actors) do
  actor:update()
 end
end

function _draw()
 frame+=1
 cls()
 room:draw()
 for actor in all(actors) do
  actor:draw()
 end
 player:draw()
 if show_x then
  print("spd.x",0,80,8)
  logger:draw("spd.x",-2,2,8)
  print("pos.x",0,88,9)
  logger:draw("pos.x",0,128,9)
 end
 if show_y then
  print("spd.y",0,96,10)
  logger:draw("spd.y",-2,2,10)
  print("pos.y",0,104,11)
  logger:draw("pos.y",0,128,11)
 end

 if (menu.visible) menu:draw()
end

__gfx__
000000000ddfdf000000000000ddd00000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ddf1f1f000ddd0000ddfdf000ddfdf000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000ff1f1f00ddfdf00ddf1f1f0ddf1f1f000d00d000d0000d0000000000088008808800080008880808088008080080088808080000000000000000000
0007700000ffff00ddf1f1f00ff1f1f00ff1f1f00005500000d00d000dd00dd00090909009090909000900909090009990909009009090000000000000000000
00077000000990000ff1f1f000ffff0000ffff000058d8000558d8000555500000f0f0f00f0f0f0f000f00f0f0f000fff0f0f00f00f0f0000000000000000000
007007000004400000ffff0000044000000999600500d0000000d0000008d8000070707007070707000700707070007070707007007070000000000000000000
000000000006600000044000006006000004460000000000000000000000d0000077007707700707000700777077007070707007007770000000000000000000
0000000000ddd0000006060000000000000000000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
000000000ff0ff0000000000f000f000000000000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
0990009900f00f0000f00f000fff0000008080000000000000000000000000000070707007000707000700707070007070707007007070000000000000000000
0095959000ffff0000ffff000cfc00000888780066676000600000000000000000f0f0f00f000f0f000f00f0f0f000f0f0f0f00f00f0f0000000000000000000
0009990000fcfc00f0fcfc0066e6600008e888000666000066000000000000000090909009000909000900909090009090909009009090000000000000000000
0009e900f0ffffe0f0fffef00f6f00f0008e80000060000066600000000000000088008808000080000800808088008080080008008080000000000000000000
00000009f0099000f0044f000fff00f0000800000060000066000000000000000000000000000000000000000000000000000000000000000000000000000000
00099909f0ffff00f0fff0000fff00f0000000000070000060000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001030000000000000303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404141414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
