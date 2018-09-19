spr_spawn_point=1

cls_spawn=class(function(self,pos,input_port)
 add(particles,self)
 self.x=pos.x
 self.y=128
 self.is_solid=false
 self.target_x=pos.x
 self.target_y=pos.y
 self.input_port=input_port
 self.is_doppelgaenger=false
 add_cr(function()
  self:cr_spawn()
 end)
end)

function cls_spawn:update()
end

function cls_spawn:cr_spawn()
 cr_move_to(self,self.target_x,self.target_y,1,inexpo)
 del(particles,self)
 local player=cls_player.init(v2(self.target_x,self.target_y), self.input_port)
 player.is_doppelgaenger=self.is_doppelgaenger
 cls_smoke.init(v2(self.x,self.y),spr_full_smoke,0)
end

function cls_spawn:draw()
 spr(start_sprites[self.input_port+1],self.x,self.y)
end
