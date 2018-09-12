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
 printh("MAKE BLAST")
 make_blast(player.x,player.y)
end

spr_suicide_bomb=45
powerup_colors[spr_suicide_bomb]=8
powerup_countdowns[spr_suicide_bomb]=5
tiles[spr_suicide_bomb]=cls_suicide_bomb
