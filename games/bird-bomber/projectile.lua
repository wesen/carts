cls_projectile=subclass(cls_actor,function(self,x,y,vx,vy)
 cls_actor._ctr(self,x,y)
 self.spdx=vx
 self.spdy=vy
 self.has_weight=true
 self.weight=1.2
 self.fliph=false
 self.flipv=false
 self.spr=6 -- bomb
end)

function cls_projectile:draw()
 spr(self.spr,self.x,self.y,1,1,self.fliph,self.flipy)
end

function cls_projectile:update()
 local maxfall=4
 local gravity=0.12*self.weight

 self.spdy=appr(self.spdy,maxfall,gravity)

 self.x+=self.spdx
 self.y+=self.spdy
 self.fliph=self.spdx<0

 if solid_at_offset(self,0,0) then
  glb_main_camera:add_shake(4)
  cls_boom.init(self.x,self.y,32,rnd_elt(bomb_colors))
  sfx(12)
  del(glb_actors,self)
 end
end

glb_bomb_colors={7,8,8,8,8,9,9,9,7,7,7,9,13,14,15,6}
glb_dark={[0]=0,0,1,1,2,1,5,6,2,4,9,3,1,1,8,10}

cls_boom=class(function(self,x,y,radius,color,p)
 self.x=x
 self.y=y
 self.radius=radius
 self.original_color=color
 self.p=p or 1
 self.color=color+flr(rnd(2))*(glb_dark[color]-color)
 add(glb_actors,self)
end)

function cls_boom:update()
 if self.p==2 and self.radius>4 then
  for i=1,4 do
   local rx=mrnd(1.1*self.radius)
   local ry=mrnd(1.1*self.radius)
   cls_boom.init(
      v2(mid(self.pos.x+rx,0,127),max(self.y+ry,0)),
      mrnd(0.5*self.radius),
      self.original_color)
  end

  for i=1,10 do
   cls_smoke.init(self.x,self.y,self.color)
  end
 end

 self.p+=1
 if (self.p>3) del(glb_actors,self)
end

function cls_boom:draw()
 if self.p==1 then
  circfill(self.x,self.y,self.radius,7)
 elseif self.p==2 then
  circfill(self.x,self.y,self.radius,self.color)
 else
  circ(self.x,self.y,self.radius+self.p-3,self.color)
 end
end

cls_smoke=class(function(self,x,y,color)
 self.x=x
 self.y=y
 self.color=color
 local ax,ay
 ax,ay=angle2vec(rnd(1))
 self.spdx=ax*(2+rnd(1))
 self.spdy=ay*(2+rnd(1))
 self.radius=1+rnd(3)
 self.color=color+flr(rnd(2))*(dark[color]-color)
 add(glb_actors,self)
end)

function cls_smoke:draw()
 circfill(self.x,self.y,self.radius,self.color)
end

function cls_smoke:update()
 self.radius-=0.1
 self.x+=self.spdx
 self.y+=self.spdy
 self.spdx*=0.9
 self.spdy=0.9*self.spdy-0.1
 if (self.radius<0) del(glb_actors,self)
end
