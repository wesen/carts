spr_spring_sprung=66
spr_spring_wound=67

cls_spring=class(function(self,pos)
 add(interactables,self)
 self.x=pos.x
 self.y=pos.y
 self.aax=self.x
 self.aay=self.y+5
 self.bbx=self.aax+8
 self.bby=self.aay+3
 self.sprung_time=0
end)
tiles[spr_spring_sprung]=cls_spring

function cls_spring:update()
 -- collide with players
 if self.sprung_time>0 then
  self.sprung_time-=1
 else
  for player in all(players) do
   if do_bboxes_collide(self,player) then
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
