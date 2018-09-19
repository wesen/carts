spr_balloon=24
cls_balloon_pwrup=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)
tiles[spr_balloon]=cls_balloon_pwrup

function cls_balloon_pwrup:on_powerup_start(player)
 local balloon=cls_balloon.init(player)
end

cls_balloon=subclass(cls_actor,function(self,player)
 cls_actor._ctr(self,v2(player.x,player.y))
 self.is_released=false
 self.is_solid=false
 self.player=player
 self.t=0
end)

function cls_balloon:update()
 self.t+=dt

 local solid=solid_at_offset(self,0,0)
 local is_actor,actor=self:is_actor_at(0,0)

 if solid or (is_actor and actor!=self.player) then
  self.player:clear_power_up()
  del(actors,self)
 elseif not self.is_released then
  if (self.player.is_dead) del(actors,self)
  self.x=self.player.x+sin(self.t)*3
  self.player.y=self.y+12
  if btnp(btn_action,self.player.input_port) then
   self.is_released=true
  end
 end

 self.y-=.5
end

function cls_balloon:draw()
 spr(spr_balloon,self.x,self.y)
 if not self.is_released then
  line(self.player.x+4,self.player.y,self.x+4,self.y+7,7)
 end
end


for i=0,5 do
 add(power_up_tiles,spr_balloon)
end
