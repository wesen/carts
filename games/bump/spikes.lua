spr_spikes=68

cls_spikes=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox={x=0,y=3,dimx=8,dimy=5}
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:update()
 local bbox=self:bbox()
 for player in all(players) do
  if bbox:collide(player:bbox()) then
   player:kill()
   cls_smoke.init(v2(self.x,self.y),32,0)
  end
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.px,self.y)
end
