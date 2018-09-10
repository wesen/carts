spr_spawn_point=1

cls_spawn=subclass(typ_spawn,cls_actor,function(self,pos,input_port)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.target=self.pos
 self.input_port=input_port
 self.pos=v2(self.target.x,128)
 self.spd.y=-2
 self.is_doppelgaenger=false
 add_cr(function()
  self:cr_spawn()
 end)
end)

function cls_spawn:cr_spawn()
 cr_move_to(self,self.target,1,inexpo)
 del(actors,self)
 local player=cls_player.init(self.target, self.input_port)
 player.is_doppelgaenger=self.is_doppelgaenger
 cls_smoke.init(self.pos,spr_full_smoke,0)
end

function cls_spawn:draw()
 spr(spr_spawn_point,self.pos.x,self.pos.y)
end
