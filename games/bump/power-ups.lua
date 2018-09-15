drop_min_time=60*4
drop_max_time=60*10

max_count=2

power_up_droppers={}

cls_pwrup_dropper=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 -- set spawn time between min time and max time
 self.time=0
 self.item=nil
 self.interval=1
 add(power_up_droppers,self)
end)

local pwrup_counts=0

function cls_pwrup_dropper:update()
 if self.item==nil then
  -- increment time. spawn when time's up
  self.time=(self.time%(self.interval))+1
  if self.time>=self.interval then
   printh("dropper time interval "..tostr(self.time).." "..tostr(self.interval))
   if pwrup_counts<max_count then
    local spr_idx=power_up_tiles[flr(rnd(#power_up_tiles))+1]
    printh("load spr "..tostr(spr_idx).." "..tostr(pwrup_counts))
    self.item=tiles[spr_idx].init(v2(self.x,self.y))
    self.item.tile=spr_idx
    pwrup_counts+=1
   end
   self.interval=flr(drop_min_time+(rnd(1)*(drop_max_time-drop_min_time)))
  end

 else

  -- check that item has been used before allowing another drop
  local exists=false
  for interactable in all(interactables) do
   if interactable==self.item then
    exists=true
   end
  end

  if not exists then
   printh("decreasing")
   pwrup_counts-=1
   self.item=nil
   self.interval=flr(drop_min_time+(rnd(1)*(drop_max_time-drop_min_time)))
   if pwrup_counts<max_count then
    for dropper in all(power_up_droppers) do
     dropper.time=0
    end
   end
  end
 end
end

spr_pwrup_dropper=25
tiles[spr_pwrup_dropper]=cls_pwrup_dropper


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


spr_pwrup_doppelgaenger=39
--tiles[spr_pwrup_doppelgaenger]=cls_pwrup_doppelgaenger
powerup_colors[spr_pwrup_doppelgaenger]=8

spr_pwrup_invincibility=40
--tiles[spr_pwrup_invincibility]=cls_pwrup
powerup_colors[spr_pwrup_invincibility]=9
powerup_countdowns[spr_pwrup_invincibility]=10

spr_pwrup_superspeed=41
--tiles[spr_pwrup_superspeed]=cls_pwrup
powerup_colors[spr_pwrup_superspeed]=6
powerup_countdowns[spr_pwrup_superspeed]=10

spr_pwrup_superjump=42
--tiles[spr_pwrup_superjump]=cls_pwrup
powerup_colors[spr_pwrup_superjump]=12
powerup_countdowns[spr_pwrup_superjump]=15

spr_pwrup_gravitytweak=43
--tiles[spr_pwrup_gravitytweak]=cls_pwrup
powerup_colors[spr_pwrup_gravitytweak]=9
powerup_countdowns[spr_pwrup_gravitytweak]=30

spr_pwrup_invisibility=44
--tiles[spr_pwrup_invisibility]=cls_pwrup
powerup_countdowns[spr_pwrup_invisibility]=5

spr_pwrup_shrink=46
--tiles[spr_pwrup_shrink]=cls_pwrup
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
