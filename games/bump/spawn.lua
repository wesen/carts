spr_spawn_point=1

cls_spawn=subclass(cls_actor,function(self,pos,input_port)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.target_x=self.x
 self.target_y=self.y
 self.y=128
 self.input_port=input_port
 self.spd_y=-2
 self.is_doppelgaenger=false
 add_cr(function()
  self:cr_spawn()
 end)
end)

function cls_spawn:cr_spawn()
 cr_move_to(self,self.target_x,self.target_y,1,inexpo)
 del(actors,self)
 local player=cls_player.init(v2(self.target_x,self.target_y), self.input_port)
 player.is_doppelgaenger=self.is_doppelgaenger
 cls_smoke.init(v2(self.x,self.y),spr_full_smoke,0)
end

function cls_spawn:draw()
 spr(spr_spawn_point,self.x,self.y)
end
