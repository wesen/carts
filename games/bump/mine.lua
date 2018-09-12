spr_mine=69

cls_mine=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,6,8,2)
 self.spr=spr_mine
end)

function make_blast(x,y)
 add_cr(function ()
  for i=0,20 do
   local r=outexpo(i,50,-50,20)
   circfill(x+4,y+6,r,7)
   yield()
  end
 end, draw_crs)
 for p in all(players) do
  if p.power_up!=spr_power_up_invincibility then
   local dx=p.x-x
   local dy=p.y-y
   local d=sqrt(dx*dx+dy*dy)
   if d<50 then
    p:kill()
    make_gore_explosion(v2(p.x,p.y))
   end
  end
 end
end

function cls_mine:on_player_collision(player)
 make_blast(self.x,self.y)
 del(interactables,self)
end
tiles[spr_mine]=cls_mine

cls_suicide_bomb=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)

function cls_suicide_bomb:on_powerup_stop(player)
 if (player.power_up_countdown<=0) make_blast(player.x,player.y)
end

spr_suicide_bomb=45
powerup_colors[spr_suicide_bomb]=8
powerup_countdowns[spr_suicide_bomb]=5
tiles[spr_suicide_bomb]=cls_suicide_bomb

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
 local solid=solid_at(self)
 local is_actor,actor=self:is_actor_at(0,0)
 if solid or (is_actor and actor!=self.player) then
  printh("bomb blast")
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
   self.spd_x=(self.player.flip_x and -1 or 1) + self.player.spd_x
   self.spd_y=-1
  end
 end
end

function cls_bomb:draw()
 spr(spr_bomb,self.x,self.y)
end
