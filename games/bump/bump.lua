--#include constants
--#include helpers
--#include actors
--#include bubbles
--#include room
--#include smoke

-- fade bubbles
-- gravity
-- downward collision

frame=0
dt=0
lasttime=time()

cls_player=subclass(typ_player,cls_actor,function(self)
    cls_actor._ctr(self,v2(0,6*8))
    self.flip=v2(false,false)
    self.spr=1
    self.hitbox=hitbox(v2(1,0),v2(6,8))

    self.show_smoke=false
    self.prev_input=0
    self.prev_jump=false
    -- allows for a jump to happen for 8 frames after jump button triggered
    self.jump_interval=0
    -- we consider we are on the ground for 6 frames
    self.on_ground_interval=0

    self.was_on_ground=false
end)

function cls_player:smoke(dir)
    add(actors,cls_smoke.init(self.pos,dir))
end

function cls_player:update()
    -- from celeste's player class
    local input=btn(btn_right) and 1 
       or (btn(btn_left) and -1 
       or 0)
    local jump=btn(btn_jump) and not self.prev_jump
    self.prev_jump=btn(btn_jump)
    if jump then
        self.jump_interval=8
    elseif self.jump_interval>0 then
        self.jump_interval-=1
    end

    local maxrun=1
    local accel=0.3
    local decel=0.1

    local on_ground=self:is_solid(v2(0,1))
    if on_ground then
        self.on_ground_interval=12
    elseif self.on_ground_interval>0 then
        self.on_ground_interval-=1
    end

    -- smoke when changing directions
    if input!=self.prev_input and input!=0 and on_ground then
        self:smoke(-input)
    end
    self.prev_input=input

    if (not on_ground) accel=0.2

    -- x movement
    if abs(self.spd.x)>maxrun then
        self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
    else
        self.spd.x=appr(self.spd.x,input*maxrun,accel)
    end
    if (self.spd.x!=0) self.flip.x=self.spd.x<0

    -- y movement
    local maxfall=2
    local gravity=0.12

    -- slow down at apex
    if (abs(self.spd.y)<=0.15) gravity*=0.5

    -- wall slide

    -- jump
    if self.jump_interval>0 then
        if self.on_ground_interval>0 then
            self.jump_interval=0
            self.on_ground_interval=0
            self.spd.y=-2
            self:smoke(v2(0,0))
        end
    end

    if (not on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

    self:move(self.spd)

    -- bubble instantiation
    if abs(self.spd.x)>0.9 and rnd(1)>0.93 then
        add(actors,cls_bubble.init(self.pos+v2(0,4),input))
    end

    -- animation
    if input==0 then
        self.spr=1
    else
        self.spr=1+flr(frame/4)%3
    end

    self.was_on_ground=on_ground
end

function cls_player:draw()
    spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
    local bbox=self:bbox()
    local bbox_col=8
    if self:is_solid(v2(0,0)) then
        bbox_col=9
    end
    rect(bbox.aa.x,bbox.aa.y,bbox.bb.x-1,bbox.bb.y-1,bbox_col)

    print(self.spd:str(),64,64)
end

player=cls_player.init()

--#include main