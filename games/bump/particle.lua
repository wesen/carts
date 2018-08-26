cls_particle=subclass(typ_particle,cls_actor,function(self,pos,lifetime,sprs)
 cls_actor._ctr(self,pos+v2(mrnd(1),0))
 self.flip=v2(false,false)
 self.t=0
 self.lifetime=lifetime
 self.sprs=sprs
 self.is_solid=false
 self.weight=0
 self.spd=v2(0,0)
end)

function cls_particle:random_flip()
 self.flip=v2(maybe(),maybe())
end

function cls_particle:random_angle(spd)
 self.spd=angle2vec(rnd(1))*spd
end

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(actors,self)
   return
 end

 local on_ground=solid_at(self:bbox(v2(0,1)))
 if on_ground then
  self.spd.y*=-0.9
 end
 self:move(self.spd)
 local maxfall=2
 local gravity=0.12*self.weight
 self.spd.y=appr(self.spd.y,maxfall,gravity)


end

function cls_particle:draw()
 local idx=flr(#self.sprs*(self.t/self.lifetime))
 local spr_=self.sprs[1+idx]
 spr(spr_,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

function make_explosion(pos,n,sprs)
 for i=0,n do
  local p=cls_particle.init(pos,0.5+rnd(2),sprs)
  p.hitbox=hitbox(v2(2,2),v2(3,3))
  p:random_angle(1)
  p.spd.x*=0.5+rnd(0.5)
  p.weight=0.5+rnd(1)
  p:random_flip()
 end
end