spr_spikes=68

cls_spikes=class(function(self,pos)
 add(interactables,self)
 self.x=pos.x
 self.y=pos.y
 self.aax=self.x
 self.aay=self.y+3
 self.bbx=self.aax+8
 self.bby=self.aay+5
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:update()
 for player in all(players) do
  if do_bboxes_collide(self,player) then
   player:kill()
   cls_smoke.init(v2(self.x,self.y),32,0)
  end
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.x,self.y)
end
