
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
 if (self.tile==spr_bomb and rnd(1)<0.3) cls_fuse_particle.init(v2(self.x,self.y))
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


spr_pwrup_doppelgaenger=39

spr_pwrup_invincibility=40
powerup_colors[spr_pwrup_invincibility]=9
powerup_countdowns[spr_pwrup_invincibility]=10

spr_pwrup_superspeed=41
powerup_colors[spr_pwrup_superspeed]=6
powerup_countdowns[spr_pwrup_superspeed]=10

spr_pwrup_superjump=42
powerup_colors[spr_pwrup_superjump]=12
powerup_countdowns[spr_pwrup_superjump]=15

spr_pwrup_gravitytweak=43
powerup_colors[spr_pwrup_gravitytweak]=9
powerup_countdowns[spr_pwrup_gravitytweak]=30

spr_pwrup_invisibility=44
powerup_countdowns[spr_pwrup_invisibility]=5

spr_pwrup_shrink=46
powerup_countdowns[spr_pwrup_shrink]=10

-- start offset for the item sprite values
spr_idx_start=39
-- associate sprite value with class
tiles[spr_pwrup_doppelgaenger]=cls_pwrup_doppelgaenger
tiles[spr_pwrup_invisibility]=cls_pwrup
tiles[spr_pwrup_shrink]=cls_pwrup
tiles[spr_pwrup_invincibility]=cls_pwrup
tiles[spr_pwrup_superjump]=cls_pwrup
tiles[spr_pwrup_superspeed]=cls_pwrup
tiles[spr_pwrup_gravitytweak]=cls_pwrup

power_up_tiles={
 spr_pwrup_doppelgaenger,
 -- spr_pwrup_invincibility,
 -- spr_pwrup_superjump,
 spr_pwrup_invisibility,
 spr_pwrup_invisibility,
 spr_pwrup_invisibility,
 -- spr_pwrup_superspeed,
 -- spr_pwrup_gravitytweak,
 spr_pwrup_shrink
}
