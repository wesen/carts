glb_actors={}

cls_actor=class(function(self,x,y)
 self.x=x
 self.y=y
 self.spdx=0
 self.spdy=0
 self.is_solid=true
 self.hitbox={x=0.5,y=0.5,dimx=7,dimy=7}
 self:update_bbox()
 add(glb_actors,self)
end)

function cls_actor:update_bbox()
 self.aax=self.hitbox.x+self.x
 self.aay=self.hitbox.y+self.y
 self.bbx=self.aax+self.hitbox.dimx
 self.bby=self.aay+self.hitbox.dimy
end

function cls_actor:draw()
end

function cls_actor:update()
end

function cls_actor:move_x(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   local solid=solid_at_offset(self,step,0)
   local actor=self:is_actor_at(step,0)

   if solid or actor then
    if abs(step)<0.1 then
     self.spdx=0
     break
    else
     amount/=2
    end
   else
    amount-=step
    self.x+=step
    self.aax+=step
    self.bbx+=step
   end
  end
 else
  self.x+=amount
  self.aax+=amount
  self.bbx+=amount
 end
end

function cls_actor:move_y(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)

   local solid=solid_at_offset(self,0,step)
   local actor,a=self:is_actor_at(0,step)

   if solid or actor then
    if abs(step)<0.1 then
     self.spdy=0
     break
    else
     amount/=2
    end
   else
    amount-=step
    self.y+=step
    self.aay+=step
    self.bby+=step
   end
  end
 else
  self.y+=amount
  self.aay+=amount
  self.bby+=amount
 end
end

function cls_actor:is_actor_at(x,y)
 for actor in all(glbl_actors) do
  if (actor.is_solid and self!=actor and do_bbox_collide_offset(self,actor,x,y)) return true,actor
 end
 return false
end
