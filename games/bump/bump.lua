--#include constants
--#include helpers
--#include actors
--#include bubbles
--#include room
--#include smoke

-- fade bubbles
-- x gravity
-- x downward collision
-- wall jump
-- x wall slide
-- add wall slide smoke
-- variable jump time
-- go through right and come back left (?)
-- add tweaking menu
-- add ice
-- add second player

frame=0
dt=0
lasttime=time()

cls_player=subclass(typ_player,cls_actor,function(self)
    cls_actor._ctr(self,v2(0,6*8))
    self.flip=v2(false,false)
    self.spr=1
    self.hitbox=hitbox(v2(2,0),v2(4,8))
    self.atk_hitbox=hitbox(v2(1,0),v2(6,4))

    self.show_smoke=false
    self.prev_input=0
    self.prev_jump=false
    -- allows for a jump to happen for 8 frames after jump button triggered
    self.jump_interval=0
    -- we consider we are on the ground for 12 frames
    self.on_ground_interval=0

    self.was_on_ground=false
end)

function cls_player:smoke(spr,dir)
    add(actors,cls_smoke.init(self.pos,spr,dir))
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
    local accel=0.4
    local decel=0.2

    local on_ground=self:would_collide(v2(0,1))
    if on_ground then
        self.on_ground_interval=12
    elseif self.on_ground_interval>0 then
        self.on_ground_interval-=1
    end

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
    if (abs(self.spd.y)<=0.15) gravity*=0.5

    -- wall slide
    local is_wall_sliding=false
    if input!=0 and self:would_collide(v2(input,0)) and not on_ground then
        is_wall_sliding=true
        maxfall=0.4
        local smoke_dir = self.flip.x and .3 or -.3
        if (maybe(.1)) self:smoke(spr_full_smoke,smoke_dir)
    end

    -- jump
    if self.jump_interval>0 then
        if self.on_ground_interval>0 then
            self.jump_interval=0
            self.on_ground_interval=0
            self.spd.y=-2
            self:smoke(spr_ground_smoke,0)
        end
    end

    if (not on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

    self:move(self.spd)

    -- animation
    if input==0 then
        self.spr=1
    elseif is_wall_sliding then
        self.spr=4
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

player=cls_player.init()

--#include main