cls_player=class(function(self)
 self.pos=v2(64,48)
 self.spd=v2(0,0)
 self.spr=1
 self.flip=v2(false,false)

 self.hitbox=hitbox(v2(2,0),v2(4,8))
end)

function cls_player:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return self.hitbox:to_bbox_at(self.pos+offset)
end

function cls_player:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
 self:bbox():draw(8)
end

function cls_player:update()
 self.spr=1+flr(frame/4)%3
end
