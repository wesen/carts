spr_moth=5

cls_moth=subclass(typ_moth,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.flip=v2(false,false)
 self.target=self.pos:clone()
 self.target_dist=0
 self.found_lamp=false
 self.new_light_debounce=0
 self.ghosts={}
 self.heart_hitbox=hitbox(v2(-3,-3),v2(8+6,8+6))
 self.heart_debounce=0
 del(actors,self)
 moth=self
end)

tiles[spr_moth]=cls_moth

function cls_moth:get_nearest_lamp()
 local nearest_lamp=nil
 local dir=nil
 local dist=10000
 for _,lamp in pairs(room.lamps) do
  if lamp.is_on then
   local v=(lamp.pos-self.pos)
   local d=v:magnitude()
   if d<dist and d<moth_los_limit then
    if self:is_lamp_visible(lamp) then
     dist=d
     dir=v
     nearest_lamp=lamp
    end
   end
  end
 end

 return nearest_lamp,dir
end

function cls_moth:is_lamp_visible(lamp)
 local ray=bbox(self.pos+v2(4,4),lamp.light_position)
 for tile in all(room.opaque_tiles) do
  local p=isect(ray,tile)
  if (#p>0) return false
 end
 return true
end

function cls_moth:update()
 self.new_light_debounce=max(0,self.new_light_debounce-1)

 if self.new_light_debounce==0 then
  local nearest_lamp=self:get_nearest_lamp()
  if nearest_lamp!=nil then
   local p=nearest_lamp.light_position
   if p!=self.target then
    self.new_light_debounce=60
    self.target=nearest_lamp.light_position
    self.found_lamp=true
   end
  elseif self.found_lamp then
   self.found_lamp=false
   self.target=self.pos:clone()
  end
 end

 local maxvel=.8
 local accel=0.05
 local dist=self.target-self.pos
 self.target_dist=dist:magnitude()

 local spd=v2(0,0)
 if self.target_dist>1 then
  spd=dist/self.target_dist*maxvel
 end
 self.spd.x=appr(self.spd.x,spd.x,accel)+mrnd(accel)
 self.spd.y=appr(self.spd.y,spd.y,accel)+mrnd(accel)

 if (abs(self.spd.x)>0.2) self.flip.x=self.spd.x<0
 self:move(self.spd)

 self.spr=spr_moth+flr(frame/8)%3

 if self.spd:sqrmagnitude()>0.1 and #self.ghosts<7 then
  if (frame%5==0) insert(self.ghosts,self.pos:clone())
 else
  popend(self.ghosts)
 end

 -- heart collision
 if player!=nil and self.heart_hitbox:to_bbox_at(self.pos):collide(player:bbox()) then
  if self.heart_debounce<=0 then
   cls_heart.init(self.pos)
   sfx(rnd_elt({41,42,43,44,45,46,47}))
   self.heart_debounce=48+rnd(32)
  else
   self.heart_debounce-=1
  end
 else
  self.heart_debounce=0
 end
end

function cls_moth:draw()
 local cols={6,6,13,13,5,1,1}
 for i,ghost in pairs(self.ghosts) do
  circfill(ghost.x+4,ghost.y+4,.5,cols[i])
 end

 bspr(self.spr,self.pos.x,self.pos.y,self.flip.x,self.flip.y,0)
end