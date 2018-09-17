cls_particle=class(function(self,pos,lifetime,sprs)
 self.x=pos.x+mrnd(1)
 self.y=pos.y
 add(particles,self)
 self.flip=v2(false,false)
 self.t=0
 self.lifetime=lifetime
 self.sprs=sprs
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
 self.aax=self.x+2
 self.bbx=self.x+4
 self.aay=self.y+2
 self.bby=self.y+4
 self.t+=dt

 if self.t>self.lifetime then
   del(particles,self)
   return
 end

 self.x+=self.spd_x
 self.aax+=self.spd_x
 self.bbx+=self.spd_x
 self.y+=self.spd_y
 self.aay+=self.spd_y
 self.bby+=self.spd_y
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
--  elseif tile_flag_at_offset(self,flg_solid,0,-1) then
--   self.spd_y*=-0.9
elseif tile_flag_at_offset(self,flg_solid,dir,0) then
  self.spd_x*=-0.9
 end
end

function make_gore_explosion(pos)
 for i=0,10 do
  cls_gore.init(pos)
 end
end

cls_score_particle=class(function(self,pos,val,c2,c1)
 self.x=pos.x
 self.y=pos.y
 self.spd_x=mrnd(0.2)
 self.spd_y=-rnd(0.2)-0.2
 self.c2=c2
 self.c1=c1
 self.val=val
 self.t=0
 self.lifetime=2
 add(particles,self)
end)

function cls_score_particle:update()
 self.t+=dt
 self.x+=self.spd_x+rnd(.1)
 self.y+=self.spd_y
 if (self.t>self.lifetime) del(particles,self)
end

function cls_score_particle:draw()
 bstr(self.val,self.x,self.y,self.c1,self.c2)
end

cls_pwrup_particle=class(function(self,x,y,a,cols)
 self.spd_x=cos(a)*.8
 self.cols=cols
 self.spd_y=sin(a)*.8
 self.x=x+self.spd_x*5
 self.y=y+self.spd_y*5
 self.t=0
 self.lifetime=0.8
 add(particles,self)
end)

function cls_pwrup_particle:update()
 self.t+=dt
 self.y+=self.spd_y
 self.x+=self.spd_x
 self.spd_y*=0.9
 self.spd_x*=0.9
 if (self.t>self.lifetime) del(particles,self)
end

function cls_pwrup_particle:draw()
 local col=self.cols[flr(#self.cols*self.t/self.lifetime)+1]
 circ(self.x,self.y,(2-self.t/self.lifetime*2),col)
end
