pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
typ_player=0
typ_smoke=1
typ_bubble=2
typ_button=3

flg_solid=0
flg_ice=1

btn_right=1
btn_left=0
btn_jump=4

tile_spring=66

frame=0
dt=0
lasttime=time()

tiles={}



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

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
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
actors={}
actor_cnt=0

cls_actor=class(typ,function(self,pos)
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
            if not self:would_collide(v2(step,0)) then
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
            if not self:would_collide(v2(0,step)) then
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

function cls_actor:would_collide(offset)
    return solid_at(self:bbox(offset))
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

cls_button=class(typ_button,function(self,btn_nr)
    self.btn_nr=btn_nr
    self.is_down=false
    self.is_pressed=false
    self.down_duration=0
    self.hold_time=0
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
room={pos=v2(0,0)}

function load_room(pos)
    room.pos=pos
    for i=0,15 do
        for j=0,15 do
            local t=tiles[tile_at(i,j)]
            if t!=nil then
                t.init(v2(i,j))
            end
        end
    end
end

function room_draw()
    map(room.pos.x,room.pos.y,0,0)
end

function solid_at(bbox)
    return bbox.aa.x<0 
        or bbox.bb.x>128
        or bbox.aa.y<0
        or bbox.bb.y>128
        or tile_flag_at(bbox,flg_solid)
end

function ice_at(bbox)
    return tile_flag_at(bbox,flg_ice)
end

function tile_at(x,y)
    return mget(room.pos.x*16+x,room.pos.y*16+y)
end

function tile_flag_at(bbox,flag)
    local x0=max(0,flr(bbox.aa.x/8))
    local x1=min(15,(bbox.bb.x-1)/8)
    local y0=max(0,flr(bbox.aa.y/8))
    local y1=min(15,(bbox.bb.y-1)/8)
    for i=x0,x1 do
        for j=y0,y1 do
            if fget(tile_at(i,j),flag) then
                return true
            end
        end
    end
    return false
end
spr_wall_smoke=54
spr_ground_smoke=51
spr_full_smoke=48

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
    spr(self.spr,self.pos.x,self.pos.y)
end
cls_player=subclass(typ_player,cls_actor,function(self)
    cls_actor._ctr(self,v2(0,6*8))
    -- players are handled separately
    del(actors,self)

    self.flip=v2(false,false)
    self.jump_button=cls_button.init(btn_jump)
    self.spr=1
    self.hitbox=hitbox(v2(2,0),v2(4,8))
    self.atk_hitbox=hitbox(v2(1,0),v2(6,4))

    self.show_smoke=false
    self.prev_input=0
    -- we consider we are on the ground for 12 frames
    self.on_ground_interval=0

    self.was_on_ground=false
end)

function cls_player:smoke(spr,dir)
    cls_smoke.init(self.pos,spr,dir)
end

function cls_player:update()
    -- from celeste's player class
    local input=btn(btn_right) and 1 
       or (btn(btn_left) and -1 
       or 0)

    self.jump_button:update()

    local maxrun=1
    local accel=0.4
    local decel=0.2

    local on_ground=self:would_collide(v2(0,1))
    if on_ground then
        self.on_ground_interval=ground_grace_interval
    elseif self.on_ground_interval>0 then
        self.on_ground_interval-=1
    end
    local on_ground_recently=self.on_ground_interval>0

    -- smoke when changing directions
    if input!=self.prev_input and input!=0 and on_ground then
        self:smoke(spr_ground_smoke,-input)
    end
    self.prev_input=input

    if not on_ground then
        accel=0.2
        decel=0.1
    end

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
    if input!=0 and self:would_collide(v2(input,0)) and not on_ground then
        is_wall_sliding=true
        maxfall=0.4
        local smoke_dir = self.flip.x and .3 or -.3
        if (maybe(.1)) self:smoke(spr_wall_smoke,smoke_dir)
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
            local wall_dir=self:would_collide(v2(-3,0)) and -1 
                          or self:would_collide(v2(3,0)) and 1 
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

    self.was_on_ground=on_ground
end

function cls_player:draw()
    spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
    local bbox=self:bbox()
    local bbox_col=8
    if self:would_collide(v2(0,0)) then
        bbox_col=9
    end

    --[[
    bbox:draw(bbox_col)
    bbox=self.atk_hitbox:to_bbox_at(self.pos)
    bbox:draw(12)
    print(self.spd:str(),64,64)
    ]]
end


cls_spring=subclass(typ_spring,cls_actor,function(self,pos)
    cls_actor._ctr(self,pos)
    self.spr=66
end)
tiles[tile_spring]=cls_spring

function cls_spring:update()
end


-- fade bubbles
-- x gravity
-- x downward collision
-- x wall slide
-- x add wall slide smoke
-- x fall down faster
-- x wall jump
-- x variable jump time
-- player spawn points
-- go through right and come back left (?)
-- add tweaking menu
-- add ice
-- add second player
-- parallax b ackground
-- springs
-- spikes

player=cls_player.init()

function _init()
    load_room(v2(0,0))
end

function _draw()
    frame+=1

    cls()
    room_draw()
    draw_actors()
    player:draw()
end

function _update60()
    dt=time()-lasttime
    lasttime=time()
    player:update()
    update_actors()
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000770700000770000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000000000000
70000600007700667000007000000000000000000000000000000600000077000700000000000000000000000000000000000000000000000000000000000000
00770000006600000000006700000000000000000000000000000007000060000660000000000000000000000000000000000000000000000000000000000000
07766000000000000000000000000000000000000000000000007077000000000000070000000000000000000000000000000000000000000000000000000000
06777700000000000000000000000000000000000000000000077777000700700000060000000000000000000000000000000000000000000000000000000000
07777600000000070000000000077700000077000000007000006676007700600000000000000000000000000000000000000000000000000000000000000000
00766007007000000000007000777600770067700700006000000066000670000070000000000000000000000000000000000000000000000000000000000000
00000006766070000700076007667770760006600000000000000006000000000060000000000000000000000000000000000000000000000000000000000000
33333333666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44433544776677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9444554477c67c760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444449ccc677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44594444ccc6cccc0566665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44459444777cc7c600d00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444447c76cccc000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444777ccccc00d00d0005666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000040404000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000404200000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040414141414040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
