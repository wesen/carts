cls_room=class(typ_room,function(self,pos,dim)
 self.pos=pos
 self.dim=dim
 self.spawn_locations={}
 self.lamps={}

 room=self

 -- initialize tiles
 for i=0,self.dim.x do
  for j=0,self.dim.y do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   if tile==spr_spawn_point then
    add(self.spawn_locations,p*8)
   end
   local t=tiles[tile]
   if (t!=nil) t.init(p*8,tile)
  end
 end
end)

function cls_room:bbox()
 return bbox(v2(0,0),self.dim*8)
end

function cls_room:get_friction(tile,dir)
 local accel=0.3
 local decel=0.2

 if (fget(self:tile_at(tile),flg_ice)) accel,decel=min(accel,0.1),min(decel,0.03)

 return accel,decel
end

function cls_room:draw()
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
end

function cls_room:spawn_player()
 cls_spawn.init(self.spawn_locations[1]:clone())
end

function cls_room:tile_at(pos)
 local v=self.pos+pos
 return mget(v.x,v.y)
end

function solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>room.dim.x*8
  or bbox.aa.y<0
  or bbox.bb.y>room.dim.y*8 then
   return true,nil
 else
  return tile_flag_at(bbox,flg_solid)
 end
end

function ice_at(bbox)
 return tile_flag_at(bbox,flg_ice)
end

function tile_at(x,y)
 return room:tile_at(v2(x,y))
end

function tile_flag_at(bbox,flag)
 local bb=bbox:to_tile_bbox()
 for i=bb.aa.x,bb.bb.x do
  for j=bb.aa.y,bb.bb.y do
   if fget(tile_at(i,j),flag) then
    return true,v2(i,j)
   end
  end
 end
 return false
end