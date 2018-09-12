spr_mine=69

cls_mine=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,6,8,2)
 self.spr=spr_mine
end)

function cls_mine:on_player_collision(player)
 add_cr(function ()
  for i=0,20 do
   local r=outexpo(i,50,-50,20)
   circfill(self.x+4,self.y+6,r,7)
   yield()
  end
 end, draw_crs)
 for p in all(players) do
  if player.power_up!=spr_power_up_invincibility then
   local dx=p.x-self.x
   local dy=p.y-self.y
   local d=sqrt(dx*dx+dy*dy)
   if d<50 then
    player:kill()
    make_gore_explosion(v2(player.x,player.y))
   end
  end
 end
 del(interactables,self)
end

tiles[spr_mine]=cls_mine
