spr_bomb=23
cls_bomb_pwrup=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)
tiles[spr_bomb]=cls_bomb_pwrup

function cls_bomb_pwrup:on_powerup_start(player)
 local bomb=cls_bomb.init(player)
end

cls_bomb=subclass(cls_actor,function(self,player)
 cls_actor._ctr(self,v2(player.x,player.y))
 self.is_thrown=false
 self.is_solid=false
 self.player=player
end)

function cls_bomb:update()
 local solid=solid_at_offset(self,0,0)
 local is_actor,actor=self:is_actor_at(0,0)
 if solid or (is_actor and actor!=self.player) then
  make_blast(self.x,self.y)
  del(actors,self)
 elseif self.is_thrown then
  local gravity=0.12
  local maxfall=2
  self.x+=self.spd_x
  self.spd_y=appr(self.spd_y,maxfall,gravity)
  self.y+=self.spd_y
 elseif self.player.is_dead then
  del(actors,self)
 else
  self.x=self.player.x
  self.y=self.player.y-8
  if btnp(btn_action,self.player.input_port) then
   self.is_thrown=true
   self.spd_x=(self.player.flip.x and -1 or 1) + self.player.spd_x
   self.spd_y=-1
  end
 end
end

function cls_bomb:draw()
 spr(spr_bomb,self.x,self.y)
end
