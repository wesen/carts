spr_spikes=68

cls_spikes=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,3,8,5)
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:on_player_collision(player)
 player:kill()
 cls_smoke.init(v2(self.x,self.y),32,0)
end

function cls_spikes:draw()
 spr(spr_spikes,self.x,self.y)
end
