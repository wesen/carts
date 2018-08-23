--#include helpers
--#include actors

frame=0

cls_player=class(typ_player,function(self)
    cls_actor._ctr(self,v2(0,6*8))
end)

function cls_player:update()
end

function cls_player:draw()
    spr(1+flr(frame/4)%3,self.pos.x,self.pos.y)
end

player=cls_player.init()
add(actors,player)

--#include main