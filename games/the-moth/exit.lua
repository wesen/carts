spr_exit_on=100
spr_exit_off=102

cls_exit=subclass(typ_exit,cls_lamp,function(self,pos,tile)
 cls_lamp._ctr(self,pos,tile)
 self.hitbox=hitbox(v2(0,0),v2(16,16))
 self.player_near=false
 self.moth_near=false
end)

tiles[spr_exit_off]=cls_exit
tiles[spr_exit_on]=cls_exit

function cls_exit:update()
 self.player_near=player!=nil and player:collides_with(self)

 self.moth_near=moth!=nil and moth:collides_with(self)
 if self.player_near and self.moth_near and btnp(btn_action) then
  printh("NEXT LEVEL")
 end
end

function cls_exit:draw()
 local spr_=self.is_on and spr_exit_on or spr_exit_off
 spr(spr_,self.pos.x,self.pos.y,2,2)
end

function cls_exit:draw_text()
 if self.player_near and self.moth_near and flr(frame/32)%2==1 then
  local pos=main_camera:abs_position(v2(50,64))
  bstr("\x97 - exit",self.pos.x-4,self.pos.y-10,0,14)
 end
end