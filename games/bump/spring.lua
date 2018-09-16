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
