spr_power_up_doppelgaenger=39
spr_power_up_invincibility=40

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
 -- clear previous power
 if player.power_up==spr_power_up_doppelgaenger then
  for _p in all(players) do
   if _p.input_port==player.input_port and _p.is_doppelgaenger then
    del(players,_p)
    del(actors,_p)
    make_gore_explosion(v2(_p.x,_p.y))
   end
  end
 end

 -- add new power
 if self.tile==spr_power_up_doppelgaenger then
  for i=0,3 do
   local spawn=room:spawn_player(player.input_port)
   spawn.is_doppelgaenger=true
  end
  player.power_up=spr_power_up_doppelgaenger
  player.power_up_countdown=nil
 elseif self.tile==spr_power_up_invincibility then
  player.power_up=spr_power_up_invincibility
  player.power_up_countdown=4
 end
end

function cls_pwrup:draw()
 spr(self.tile,self.x,self.y)
end

tiles[spr_power_up_doppelgaenger]=cls_pwrup
tiles[spr_power_up_invincibility]=cls_pwrup
powerup_colors={}
powerup_colors[spr_power_up_doppelgaenger]=8
powerup_colors[spr_power_up_invincibility]=9
