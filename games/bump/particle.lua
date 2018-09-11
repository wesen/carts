cls_particle=subclass(cls_actor,function(self,pos,lifetime,sprs)
 cls_actor._ctr(self,pos+v2(mrnd(1),0))
 del(actors,self)
 add(particles,self)
 self.flip=v2(false,false)
 self.t=0
 self.lifetime=lifetime
 self.sprs=sprs
 self.is_solid=false
 self.weight=0
end)

function cls_particle:random_flip()
 self.flip=v2(maybe(),maybe())
end

function cls_particle:random_angle(spd)
 local v=angle2vec(rnd(1))
 self.spd_x=v.x*spd
 self.spd_y=v.y*spd
end

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(particles,self)
   return
 end

 self.x+=self.spd_x
 self.y+=self.spd_y
 self.spd_y=appr(self.spd_y,2,0.12)
end

function cls_particle:draw()
 local idx=flr(#self.sprs*(self.t/self.lifetime))
 local spr_=self.sprs[1+idx]
 spr(spr_,self.x,self.y,1,1)
end

cls_gore=subclass(cls_particle,function(self,pos)
 cls_particle._ctr(self,pos,0.5+rnd(2),{35,36,37,38,38})
 self.hitbox={x=2,y=2,dimx=3,dimy=3}
 self:random_angle(1)
 self.spd_x*=0.5+rnd(0.5)
 self.weight=0.5+rnd(1)
 -- self:random_flip()
end)

function cls_gore:update()
 cls_particle.update(self)

 -- i tried generalizing this but it's just easier to write it out
 local dir=sign(self.spd_x)
 if tile_flag_at_offset(self,flg_solid,0,1) then
  self.spd_y*=-0.9
 -- elseif solid_at(self:bbox(0,-1)) then
 --  self.spd_y*=-0.9
elseif tile_flag_at_offset(self,flg_solid,dir,0) then
  self.spd_x*=-0.9
 end
end

function make_gore_explosion(pos)
 for i=0,10 do
  cls_gore.init(pos)
 end
end
