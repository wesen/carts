cls_actor=class(function(self,pos)
 self.x=pos.x
 self.y=pos.y
 self.spd_x=0
 self.spd_y=0
 self.is_solid=true
 if (self.hitbox==nil) self.hitbox={x=0.5,y=0.5,dimx=7,dimy=7}
 self:update_bbox()
 add(actors,self)
end)

function cls_actor:update_bbox()
 self.aax=self.hitbox.x+self.x
 self.aay=self.hitbox.y+self.y
 self.bbx=self.aax+self.hitbox.dimx
 self.bby=self.aay+self.hitbox.dimy
end

function cls_actor:bbox(x,y)
 x=x or 0
 y=y or 0
 return setmetatable({aax=self.aax+x,aay=self.aay+y,bbx=self.bbx+x,bby=self.bby+y},bboxvt)
 -- return setmetatable({
 --    aax=self.x+self.hitbox.x+x,
 --    aay=self.y+self.hitbox.y+y,
 --    bbx=self.x+self.hitbox.x+self.hitbox.dimx+x,
 --    bby=self.y+self.hitbox.y+self.hitbox.dimy+y},
  -- bboxvt)
end

function cls_actor:str()
 return "actor["..tostr(self.id)..",t:"..tostr(self.typ).."]"
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
     self.spd_x=0
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
   local actor=self:is_actor_at(0,step)

   if solid or actor then
    if abs(step)<0.1 then
     self.spd_y=0
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
 for actor in all(actors) do
  if (actor.is_solid and self!=actor and do_bboxes_collide_offset(self,actor,x,y)) return true,actor
 end

 return false,nil
end

function draw_actors(typ)
 for a in all(actors) do
  if ((typ==nil or a.typ==typ) and a.draw!=nil) a:draw()
 end
end

function update_actors(typ)
 for a in all(actors) do
  if ((typ==nil or a.typ==typ) and a.update!=nil) a:update()
 end
end
