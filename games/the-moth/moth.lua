spr_moth=5

cls_moth=subclass(typ_moth,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.flip=v2(false,false)
end)

tiles[spr_moth]=cls_moth

function cls_moth:update()
 self.spr=spr_moth+flr(frame/8)%3
end

function cls_moth:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end