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

cls_gore=subclass(typ_gore,cls_particle,function(self,pos)
 cls_particle._ctr(self,pos,0.5+rnd(2),{35,36,37,38,38})
 self.hitbox=hitbox(v2(2,2),v2(3,3))
 self:random_angle(1)
 self.spd.x*=0.5+rnd(0.5)
 self.weight=0.5+rnd(1)
 self:random_flip()
end)

function cls_gore:update()
 cls_particle.update(self)

 local ground_bbox=self:bbox(v2(0,1))
 local on_ground=solid_at(ground_bbox)
 if on_ground then
  local tile=get_tile_location_with_flag(ground_bbox,flg_solid)
  if tile!=nil then
   room.gore[v_idx(tile)]+=1
   -- add tile gore
  end
  self.spd.y*=-0.9
 end
end

function make_gore_explosion(pos)
 for i=0,10 do
  cls_gore.init(pos)
 end
end