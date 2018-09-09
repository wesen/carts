spr_tele_enter=112
spr_tele_exit=113
tele_exits={}

cls_tele_enter=subclass(nil,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.hitbox=hitbox(v2(4,4),v2(1,1))
end)
tiles[spr_tele_enter]=cls_tele_enter

function cls_tele_enter:update()
 local bbox=self:bbox()
 for player in all(players) do
  if bbox:collide(player:bbox()) then--or btnp(btn_up,player.input_port) then
   printh("TELEPORT")
   player.pos = tele_exits[1].pos:clone()
  end
 end
end

function cls_tele_enter:draw()
 spr(spr_tele_enter,self.pos.x,self.pos.y)
end


cls_tele_exit=subclass(nil,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 add(tele_exits, self)
end)
tiles[spr_tele_exit]=cls_tele_exit

function cls_tele_exit:draw()
 spr(spr_tele_exit,self.pos.x,self.pos.y)
end
