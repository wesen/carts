cls_projectile=subclass(cls_actor,function(self,pos,spd)
 cls_actor._ctr(self,pos)
 self.spd=spd
 self.has_weight=true
 self.weight=1.2
 self.flip=v2(false,false)
 self.spr=6 -- bomb
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
  main_camera:add_shake(4)
  cls_boom.init(self.pos,32,rnd_elt(bomb_colors))
  del(actors,self)
 end
end

bomb_colors={7,8,8,8,8,9,9,9,7,7,7,9,13,14,15,6}

dark={[0]=0,0,1,1,2,1,5,6,2,4,9,3,1,1,8,10}

cls_boom=class(function(self,pos,radius,color,p)
 self.pos=pos
 self.radius=radius
 self.original_color=color
 self.p=p or 1
 self.color=color+flr(rnd(2))*(dark[color]-color)
 add(actors,self)
end)

function cls_boom:update()
 if self.p==2 and self.radius>4 then
  for i=1,4 do
   local rx=mrnd(1.1*self.radius)
   local ry=mrnd(1.1*self.radius)
   cls_boom.init(
      v2(mid(self.pos.x+rx,0,127),max(self.pos.y+ry,0)),
      mrnd(0.5*self.radius),
      self.original_color)
  end

  for i=1,10 do
   cls_smoke.init(self.pos:clone(),self.color)
  end
 end

 self.p+=1
 if (self.p>3) del(actors,self)
end

function cls_boom:draw()
 if self.p==1 then
  circfill(self.pos.x,self.pos.y,self.radius,7)
 elseif self.p==2 then
  circfill(self.pos.x,self.pos.y,self.radius,self.color)
 else
  circ(self.pos.x,self.pos.y,self.radius+self.p-3,self.color)
 end
end

cls_smoke=class(function(self,pos,color)
 self.pos=pos
 self.color=color
 self.spd=(2+rnd(1))*angle2vec(rnd(1))
 self.radius=1+rnd(3)
 self.color=color+flr(rnd(2))*(dark[color]-color)
 add(actors,self)
end)

function cls_smoke:draw()
 circfill(self.pos.x,self.pos.y,self.radius,self.color)
end

function cls_smoke:update()
 self.radius-=0.1
 self.pos+=self.spd
 self.spd.x*=0.9
 self.spd.y=0.9*self.spd.y-0.1
 if (self.radius<0) del(actors,self)
end
