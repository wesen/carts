spr_spikes=68

cls_spikes=subclass(typ_spikes,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox=hitbox(v2(0,3),v2(8,5))
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:update()
 local bbox=self:bbox()
 if player!=nil then
  if bbox:collide(player:bbox()) then
   player:kill()
   cls_smoke.init(self.pos,32,0)
  end
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.pos.x,self.pos.y)
end