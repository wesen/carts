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
   end
  end
 end
end

function cls_spring:draw()
 local spr_=spr_spring_wound
 if (self.sprung_time>0) spr_=spr_spring_sprung
 spr(spr_,self.pos.x,self.pos.y)
end