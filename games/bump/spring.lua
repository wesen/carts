spr_spring_sprung=66
spr_spring_wound=67

cls_spring=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox={x=0,y=5,dimx=8,dimy=3}
 self.sprung_time=0
 self.is_solid=false
end)
tiles[spr_spring_sprung]=cls_spring

function cls_spring:update()
 -- collide with players
 local bbox=self:bbox()
 if self.sprung_time>0 then
  self.sprung_time-=1
 else
  for player in all(players) do
   if bbox:collide(player:bbox()) then
    player.spd_y=-spring_speed
    self.sprung_time=10
    local smoke=cls_smoke.init(v2(self.x,self.y),spr_full_smoke,0)
   end
  end
 end
end

function cls_spring:draw()
 -- self:bbox():draw(9)
 local spr_=spr_spring_wound
 if (self.sprung_time>0) spr_=spr_spring_sprung
 spr(spr_,self.x,self.y)
end
