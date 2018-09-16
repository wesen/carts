spr_tele_enter=216
spr_tele_exit=200
tele_exits={}

cls_tele_enter=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,4,4,1,1)
end)
tiles[spr_tele_enter]=cls_tele_enter

function cls_tele_enter:on_player_collision(player)
 if player.on_ground and not player.is_teleporting then
  sfx(33)
  add_cr(function()
   player.is_teleporting=true
   player.spd=v2(0,0)
   player.ghosts={}

   local anim_length=10
   for i=0,anim_length do
    local w=i/anim_length*10
    rectfill(player.x+4-w,player.y+4-w,player.x+4+w,player.y+4+w,7)
    yield()
   end
   local exit=rnd_elt(tele_exits)
   player.x,player.y=exit.x,exit.y
   for i=0,anim_length do
    local w=(anim_length-i)/anim_length*10
    rectfill(player.x+4-w,player.y+4-w,player.x+4+w,player.y+4+w,7)
    yield()
   end
   player.is_teleporting=false
  end,draw_crs)
 end
end

function cls_tele_enter:draw()
 spr(self.tile+(frame/4)%3,self.x,self.y)
end


cls_tele_exit=class(function(self,pos)
 self.x=pos.x
 self.y=pos.y
 add(tele_exits,self)
 add(static_objects,self)
end)
tiles[spr_tele_exit]=cls_tele_exit

function cls_tele_exit:update()
end

function cls_tele_exit:draw()
 spr(self.tile+(frame/4)%3,self.x,self.y)
end
