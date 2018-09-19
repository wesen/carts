spr_bomb=23
cls_bomb_pwrup=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)
tiles[spr_bomb]=cls_bomb_pwrup

function make_blast(x,y,radius)
 add_cr(function ()
  for i=0,20 do
   local r=outexpo(i,radius,-radius,20)
   circfill(x+4,y+6,r,7)
   yield()
  end
 end, draw_crs)
 add_shake(5)
 sfx(4)
 for p in all(players) do
  if p.power_up!=spr_pwrup_invincibility then
   local dx=p.x-x
   local dy=p.y-y
   local d=sqrt(dx*dx+dy*dy)
   if d<radius then
    p:add_score(-1)
    p:kill()
    make_gore_explosion(v2(p.x,p.y))
   end
  end
 end
end

function cls_bomb_pwrup:on_powerup_start(player)
 local bomb=cls_bomb.init(player)
end

fuse_cols={8,9,10,7}
cls_fuse_particle=class(function(self,pos)
 self.x=pos.x+6
 self.y=pos.y+1
 local v=angle2vec(mrnd(0.5))*0.2
 self.spd_x=v.x
 self.spd_y=v.y
 self.t=0
 self.lifetime=rnd(1)
 add(particles,self)
end)

function cls_fuse_particle:update()
 self.t+=dt
 self.x+=self.spd_x+rnd(.5)
 self.y+=self.spd_y+mrnd(.3)
 if (self.t>self.lifetime) del(particles,self)
end

function cls_fuse_particle:draw()
 circfill(self.x,self.y,.5,fuse_cols[flr(#fuse_cols*self.t/self.lifetime)+1])
end

cls_bomb=subclass(cls_actor,function(self,player)
 cls_actor._ctr(self,v2(player.x,player.y))
 self.is_thrown=false
 self.is_solid=false
 self.player=player
 self.time=5
 self.name="bomb"
end)

function cls_bomb:update()
 if (rnd(1)<0.5) cls_fuse_particle.init(v2(self.x,self.y))

 self.time-=dt
 if self.time<0 then
  make_blast(self.x,self.y,45)
  del(actors,self)
 end

 if self.is_thrown then
  local solid=solid_at_offset(self,0,0)
  local actor,a=self:is_actor_at(0,0)
  if not self.is_solid and not solid and not actor then
   -- avoid a bomb getting stuck on a wall when thrown
   self.is_solid=true
  end

  local gravity=0.12
  local maxfall=2
  self.spd_y=appr(self.spd_y,maxfall,gravity)
  cls_actor.move_x(self,self.spd_x)
  cls_actor.move_y(self,self.spd_y)

  if self.is_solid then
   if tile_flag_at_offset(self,flg_solid,0,1) then
    self.spd_y*=-0.8
   elseif tile_flag_at_offset(self,flg_solid,sign(self.spd_x),0) then
    self.spd_x*=-0.85
   end
  end
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

for i=0,4 do
 add(power_up_tiles,spr_bomb)
end
