pwrup_drop_interval=60*10


cls_pwrup_dropper=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.time=0
 self.item=nil
end)

function cls_pwrup_dropper:update()
 if self.item==nil then

  -- Increment time. Spawn when time's up
  self.time=(self.time%(pwrup_drop_interval))+1
  if self.time==pwrup_drop_interval then
   self.item=rnd_elt(power_ups).init(self.pos)
  end

 else

  -- Check that item has been used before allowing another drop
  local exists=false
  for actor in all(actors) do
   if actor==self.item then
    exists=true
   end
  end

  if not exists then
   self.item=nil
  end

 end
end


cls_pwrup=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,0,8,8)
end)

function cls_pwrup:on_player_collision(player)
 if player.power_up!=nil then
  player:clear_power_up()
 end

 self:on_powerup_start(player)
 player.power_up=self
 player.power_up_type=self.tile
 player.power_up_countdown=powerup_countdowns[self.tile]

  del(interactables,self)
end

function cls_pwrup:on_powerup_start(player)
end

function cls_pwrup:on_powerup_stop(player)
end

function cls_pwrup:draw()
 spr(self.tile,self.x,self.y)
end

cls_pwrup_doppelgaenger=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)

function cls_pwrup_doppelgaenger:on_powerup_stop(player)
 for _p in all(players) do
  if _p.input_port==player.input_port and _p.is_doppelgaenger then
   del(players,_p)
   del(actors,_p)
   make_gore_explosion(v2(_p.x,_p.y))
  end
 end
end

function cls_pwrup_doppelgaenger:on_powerup_start(player)
 for i=0,3 do
  local spawn=room:spawn_player(player.input_port)
  spawn.is_doppelgaenger=true
 end
end

powerup_colors={}
powerup_countdowns={}

spr_power_up_doppelgaenger=39
--tiles[spr_power_up_doppelgaenger]=cls_pwrup_doppelgaenger
powerup_colors[spr_power_up_doppelgaenger]=8

spr_power_up_invincibility=40
--tiles[spr_power_up_invincibility]=cls_pwrup
powerup_colors[spr_power_up_invincibility]=9
powerup_countdowns[spr_power_up_invincibility]=10

spr_power_up_superspeed=41
--tiles[spr_power_up_superspeed]=cls_pwrup
powerup_colors[spr_power_up_superspeed]=6
powerup_countdowns[spr_power_up_superspeed]=10

spr_power_up_superjump=42
--tiles[spr_power_up_superjump]=cls_pwrup
powerup_colors[spr_power_up_superjump]=12
powerup_countdowns[spr_power_up_superjump]=15

spr_power_up_gravitytweak=43
--tiles[spr_power_up_gravitytweak]=cls_pwrup
powerup_colors[spr_power_up_gravitytweak]=9
powerup_countdowns[spr_power_up_gravitytweak]=30

spr_power_up_invisibility=44
--tiles[spr_power_up_invisibility]=cls_pwrup
powerup_countdowns[spr_power_up_invisibility]=30

spr_power_up_shrink=46
--tiles[spr_power_up_shrink]=cls_pwrup
powerup_countdowns[spr_power_up_shrink]=30


power_ups={ 
 spr_power_up_doppelgaenger,
 spr_power_up_invincibility,
 spr_power_up_superspeed,
 spr_power_up_superjump,
 spr_power_up_gravitytweak,
 spr_power_up_invisibility,
 spr_power_up_shrink
}
tiles[spr_power_up_doppelgaenger]=cls_pwrup_dropper