cls_enemy=class(function(self,pos)
 self.pos=pos
end)

function cls_enemy:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return self.hitbox:to_bbox_at(self.pos+offset)
end

function cls_enemy:str()
 return "enemy["..tostr(self.id)..",t:"..tostr(self.typ).."]"
end

function cls_enemy:draw()
 rectfill(self.pos.x,self.pos.y,self.pos.x+8,self.pos.y+8,8)
end

function cls_enemy:update()
end
