spr_tele_enter=112
spr_tele_exit=113
tele_exits={}

cls_tele_enter=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.hitbox={x=4,y=4,dimx=1,dimy=1}
end)
tiles[spr_tele_enter]=cls_tele_enter

function cls_tele_enter:update()
 local bbox=self:bbox()
 for player in all(players) do
  if bbox:collide(player:bbox()) and player.on_ground and not player.is_teleporting then
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
end

function cls_tele_enter:draw()
 spr(spr_tele_enter,self.x,self.y)
end


cls_tele_exit=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 add(tele_exits, self)
end)
tiles[spr_tele_exit]=cls_tele_exit

function cls_tele_exit:draw()
 spr(spr_tele_exit,self.x,self.y)
end
