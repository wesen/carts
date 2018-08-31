spr_exit_on=100
spr_exit_off=102

cls_exit=subclass(typ_exit,cls_lamp,function(self,pos,tile)
 cls_lamp._ctr(self,pos,tile)
 self.hitbox=hitbox(v2(4,4),v2(8,8))
 self.player_near=false
 self.moth_near=false
 self.activated=false
end)

tiles[spr_exit_off]=cls_exit
tiles[spr_exit_on]=cls_exit

function cls_exit:update()
 self.player_near=player!=nil and player:collides_with(self)

 self.moth_near=moth!=nil and moth:collides_with(self)
 if self.moth_near and not self.activated then
  self.activated=true
  game:next_level()
 end
end

function cls_exit:draw()
 local spr_=self.is_on and spr_exit_on or spr_exit_off
 local blink=should_blink(24)
 if (should_blink(12) or maybe(.1)) pal(8,0)
 palt(0,false)
 spr(spr_,self.pos.x,self.pos.y,2,2)
 palt()
 pal()
end
