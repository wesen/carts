spr_spikes=68

cls_spikes=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,3,8,5)
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:on_player_collision(player)
 if player.power_up!=spr_pwrup_invincibility then
  player:kill()
  sfx(1)
  player:add_score(-1)
  make_gore_explosion(v2(player.x,player.y))
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.x,self.y)
end
