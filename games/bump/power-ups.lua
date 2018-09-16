
cls_pwrup=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,0,8,8)
 self.offset=flr(rnd(30))
end)

function cls_pwrup:on_player_collision(player)
 if player.power_up!=nil then
  player:clear_power_up()
 end

 self:on_powerup_start(player)
 player.power_up=self
 player.power_up_type=self.tile
 player.power_up_countdown=powerup_countdowns[self.tile]

 if self.tile!=spr_bomb then
  local x=self.x
  local y=self.y
  local radius=20
  add_cr(function ()
   for i=0,1,0.1 do
    local p=cls_pwrup_particle.init(self.x+4,self.y+4,i,powerup_colors[self.tile])
    p.spd_x*=3
    p.spd_y*=3
   end
   for i=0,20 do
    local r=outexpo(i,radius,-radius,20)
    circfill(x+4,y+6,r,powerup_colors[self.tile][1])
    yield()
   end
  end, draw_crs)
 end

  del(interactables,self)
end

function cls_pwrup:on_powerup_start(player)
end

function cls_pwrup:on_powerup_stop(player)
end

function cls_pwrup:draw()
 if self.tile==spr_bomb then
  if (rnd(1)<0.3) cls_fuse_particle.init(v2(self.x,self.y))
  spr(self.tile,self.x,self.y)
 else
  spr(self.tile+(frame/8)%3,self.x,self.y)
  if (frame+self.offset)%40==0 then
   for i=0,1,0.1 do
    cls_pwrup_particle.init(self.x+4,self.y+4,i,powerup_colors[self.tile])
   end
  end
 end
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

spr_pwrup_doppelgaenger=197
powerup_colors[spr_pwrup_doppelgaenger]={8,2,1}

spr_pwrup_invincibility=155
powerup_colors[spr_pwrup_invincibility]={9,8,7,2}
powerup_countdowns[spr_pwrup_invincibility]=10

spr_pwrup_superspeed=41
powerup_colors[spr_pwrup_superspeed]={6,6,5,1}
powerup_countdowns[spr_pwrup_superspeed]=10

spr_pwrup_superjump=42
powerup_colors[spr_pwrup_superjump]={12,13,2,1}
powerup_countdowns[spr_pwrup_superjump]=15

spr_pwrup_gravitytweak=43
powerup_colors[spr_pwrup_gravitytweak]={9,8,2,1}
powerup_countdowns[spr_pwrup_gravitytweak]=30

spr_pwrup_invisibility=178
powerup_colors[spr_pwrup_invisibility]={9,8,2,1}
powerup_countdowns[spr_pwrup_invisibility]=5

spr_pwrup_shrink=139
powerup_colors[spr_pwrup_shrink]={11,3,6,1}
powerup_countdowns[spr_pwrup_shrink]=10

-- start offset for the item sprite values
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
