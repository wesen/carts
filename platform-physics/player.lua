cls_player=class(function(self)
 self.pos=v2(64,48)
 self.spd=v2(0,0)
 self.spr=1
 self.flip=v2(false,false)
end)

function cls_player:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

function cls_player:update()
 self.spr=1+flr(frame/4)%3
end
