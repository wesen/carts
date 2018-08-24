--#include helpers
--#include actors
--#include bubbles

frame=0
dt=0
lasttime=time()

cls_player=subclass(typ_player,cls_actor,function(self)
    cls_actor._ctr(self,v2(0,6*8))
    self.flip=v2(false,false)
    self.spr=1
end)

function cls_player:update()
    local input=btn(1) and 1 or (btn(0) and -1 or 0)
    -- from celeste's player class
    local maxrun=1
    local accel=0.5
    local decel=0.2

    if abs(self.spd.x)>maxrun then
        self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
    else
        self.spd.x=appr(self.spd.x,input*maxrun,accel)
    end

    self:move(self.spd)

    if self.spd.x!=0 then
        self.flip.x=self.spd.x<0
    end

    if input==0 then
        self.spr=1
    else
        self.spr=1+flr(frame/4)%3
    end
end

function cls_player:draw()
    printh("flipx "..tostr(self.flip.x))
    spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

player=cls_player.init()
add(actors,player)

--#include main