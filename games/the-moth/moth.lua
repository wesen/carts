spr_moth=5

cls_moth=subclass(typ_moth,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.flip=v2(false,false)
end)

tiles[spr_moth]=cls_moth

function cls_moth:update()
 self.spr=spr_moth+flr(frame/8)%3

 local nearest_lamp=nil
 local dir=nil
 local dist=10000
 for _,lamp in pairs(room.lamps) do
  if lamp.is_on then
   local v=(lamp.pos-self.pos)
   local d=v:sqrmagnitude()/10000.
   if d<dist then
    dist=d
    dir=v:normalize()
    nearest_lamp=lamp
   end
  end
 end

 if nearest_lamp!=nil then
  self.spd=dir
  self:move(self.spd)
 end
end

function cls_moth:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end