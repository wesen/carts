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
 end

 player.power_up=self.tile
 player.power_up_countdown=powerup_countdowns[self.tile]
end

function cls_pwrup:draw()
 spr(self.tile,self.x,self.y)
end

powerup_colors={}
powerup_countdowns={}

spr_power_up_doppelgaenger=39
tiles[spr_power_up_doppelgaenger]=cls_pwrup
powerup_colors[spr_power_up_doppelgaenger]=8

spr_power_up_invincibility=40
tiles[spr_power_up_invincibility]=cls_pwrup
powerup_colors[spr_power_up_invincibility]=9
powerup_countdowns[spr_power_up_invincibility]=10

spr_power_up_superspeed=41
tiles[spr_power_up_superspeed]=cls_pwrup
powerup_colors[spr_power_up_superspeed]=6
powerup_countdowns[spr_power_up_superspeed]=30
