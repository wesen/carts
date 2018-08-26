cls_bubble=subclass(typ_bubble,cls_actor,function(self,pos,dir)
 cls_actor._ctr(self,pos)
 self.spd=v2(-dir*rnd(0.2),-rnd(0.2))
 self.life=10
end)

function cls_bubble:draw()
 local size=4-self.life/3
 circ(self.pos.x,self.pos.y,size,1)
end

function cls_bubble:update()
 self.life*=0.9
 self:move(self.spd)
 if (self.life<0.1) then
  del(actors,self)
 end
end