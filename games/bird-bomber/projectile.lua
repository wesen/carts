cls_projectile=subclass(cls_actor,function(self,pos,spd)
 cls_actor._ctr(self,pos)
 self.spd=spd
 self.has_weight=true
 self.weight=1.2
 self.flip=v2(false,false)
 self.spr=6 -- bomb
 printh("projs pos "..self.pos:str())
end)

function cls_projectile:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

function cls_projectile:update()
 local maxfall=4
 local gravity=0.12*self.weight

 self.spd.y=appr(self.spd.y,maxfall,gravity)

 self.pos+=self.spd
 self.flip.x=self.spd.x<0

 if solid_at(self:bbox()) then
  printh("EXPLODE")
  del(actors,self)
 end
end
