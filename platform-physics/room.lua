flg_solid=0

cls_room=class(function(self)
 self.pos=v2(0,0)
 self.dim=v2(16,16)
end)

function cls_room:bbox()
 return bbox(v2(0,0),self.dim*8)
end

function cls_room:draw()
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
end

function cls_room:tile_at(pos)
 local v=self.pos+pos
 return mget(v.x,v.y)
end

function cls_room:solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>self.dim.x*8
  or bbox.aa.y<0
  or bbox.bb.y>self.dim.y*8 then
   return true,nil
 else
  return self:tile_flag_at(bbox,flg_solid)
 end
end

function cls_room:tile_flag_at(bbox,flag)
 local bb=bbox:to_tile_bbox()
 for i=bb.aa.x,bb.bb.x do
  for j=bb.aa.y,bb.bb.y do
   local v=v2(i,j)
   local v2=v+self.pos
   if fget(mget(v2.x,v2.y),flag) then
    return true,v
   end
  end
 end
 return false
end
