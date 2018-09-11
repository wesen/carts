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
   amount-=step

   -- bbox needs to be updated here
   local solid=self:is_solid_at(step,0)
   local actor=self:is_actor_at(step,0)
   if solid or actor then
    self.spd_x=0
    break
   else
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
   amount-=step

   local solid=self:is_solid_at(0,step)
   local actor=self:is_actor_at(0,step)

   if solid or actor then
    self.spd_y=0
    break
   else
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

function cls_actor:is_solid_at(x,y)
 return solid_at(self:bbox(x,y))
end

function cls_actor:is_actor_at(x,y)
 for actor in all(actors) do
  if actor.is_solid then
   local bbox_other = actor:bbox()
   if self!=actor and bbox_other:collide(self:bbox(x,y)) then
    return true
   end
  end
 end

 return false
end

function cls_actor:get_collisions(typ,offset)
 local res={}

 local bbox=self:bbox(offset.x,offset.y)
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
