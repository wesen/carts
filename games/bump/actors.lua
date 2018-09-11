actor_cnt=0

cls_actor=class(function(self,pos)
 self.x=pos.x
 self.y=pos.y
 self.id=actor_cnt
 actor_cnt+=1
 self.spd_x=0
 self.spd_y=0
 self.is_solid=true
 self.hitbox={x=0,y=0,dimx=8,dimy=8}
 self:update_bbox()
 add(actors,self)
end)

function cls_actor:update_bbox()
 self.aax=self.hitbox.x+self.x
 self.aay=self.hitbox.y+self.y
 self.bbx=self.aax+self.hitbox.dimx
 self.bby=self.aay+self.hitbox.dimy
end

function cls_actor:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return hitbox_to_bbox(self.hitbox,v2(self.x,self.y)+offset)
end

function cls_actor:str()
 return "actor["..tostr(self.id)..",t:"..tostr(self.typ).."]"
end

function cls_actor:move_x(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   amount-=step

   local solid=self:is_solid_at(v2(step,0))
   local actor=self:is_actor_at(v2(step,0))
   if solid or actor then
    self.spd_x=0
    break
   else
    self.x+=step
   end

  end
 else
  self.x+=amount
 end
end

function cls_actor:move_y(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   amount-=step

   local solid=self:is_solid_at(v2(0,step))
   local actor=self:is_actor_at(v2(0,step))

   if solid or actor then
    self.spd_y=0
    break
   else
    self.y+=step
   end

  end
 else
  self.y+=amount
 end
end

function cls_actor:is_solid_at(offset)
 return solid_at(self:bbox(offset))
end

function cls_actor:is_actor_at(offset)
 for actor in all(actors) do
  if actor.is_solid then
   local bbox_other = actor:bbox()
   if self!=actor and bbox_other:collide(self:bbox(offset)) then
    return true
   end
  end
 end

 return false
end

function cls_actor:get_collisions(typ,offset)
 local res={}

 local bbox=self:bbox(offset)
 for actor in all(actors) do
  if actor!=self and actor.typ==typ then
   if (bbox:collide(actor:bbox())) add(res,actor)
  end
 end

 return res
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
