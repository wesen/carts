spr_spikes=68
spr_spikes_v=71

cls_spikes=subclass(typ_spikes,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.spr=tile
 if tile==spr_spikes then
  self.hitbox=hitbox(v2(0,3),v2(8,5))
 else
  self.hitbox=hitbox(v2(0,0),v2(8,5))
 end
end)
tiles[spr_spikes]=cls_spikes
tiles[spr_spikes_v]=cls_spikes

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
 spr(self.spr,self.pos.x,self.pos.y)
 -- local bbox=self:bbox()
 -- local bbox_col=8
 -- bbox:draw(bbox_col)
end