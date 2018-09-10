spr_power_up=39

cls_pwrup=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
end)

function cls_pwrup:update()
 local bb=self:bbox()
 for player in all(players) do
  if player:bbox():collide(bb) then
   self:act_on_player(player)
   del(actors,self)
   return
  end
 end
end

function cls_pwrup:act_on_player(player)
end

function cls_pwrup:draw()
 spr(self.tile,self.pos.x,self.pos.y)
end

cls_pwrup_doppelgaenger=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)

function cls_pwrup_doppelgaenger:act_on_player(player)
 for i=0,3 do
  local spawn=room:spawn_player(player.input_port)
  spawn.is_doppelgaenger=true
 end
end

tiles[spr_power_up]=cls_pwrup_doppelgaenger
