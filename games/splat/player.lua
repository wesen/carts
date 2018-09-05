cls_player=class(function(self,pos)
 self.pos=pos
end)

function cls_player:draw()
 rectfill(self.pos.x,self.pos.y,self.pos.x+8,self.pos.y+8,7)
end

function cls_player:update()
end
