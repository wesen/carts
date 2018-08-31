spr_spawn_point=1

cls_spawn=subclass(typ_spawn,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.target=self.pos
 self.pos=v2(self.target.x,128)
 self.spd.y=-2
 add_cr(function()
  cr_move_to(self,self.target,1,inexpo)
  del(actors,self)
  cls_player.init(self.target)
  cls_smoke.init(self.pos,spr_full_smoke,0)
  sfx(32)
 end)
 add_cr(function()
  wait_for(1.1)
  main_camera:add_shake(8)
 end)
end)

function cls_spawn:cr_spawn()
end

function cls_spawn:draw()
 spr(spr_spawn_point,self.pos.x,self.pos.y)
end