function v_idx(pos)
 return pos.x+pos.y*128
end

cls_room=class(function(self,pos,dim)
 self.pos=pos
 self.dim=dim
 self.spawn_locations={}
 printh("init room")

 -- initialize tiles
 for i=0,self.dim.x-1 do
  for j=0,self.dim.y-1 do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   if tile==spr_spawn_point then
    add(self.spawn_locations,p*8)
   end
   local t=tiles[tile]
   if t!=nil then
    local a=t.init(p*8)
    a.tile=tile
   end
  end
 end
end)

function cls_room:get_friction(tile,dir)
 local accel=0.1
 local decel=0.1

 if (fget(self:tile_at(tile),flg_ice)) accel,decel=min(accel,0.1),min(decel,0.03)

 return accel,decel
end

function cls_room:draw()
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
end

function cls_room:spawn_player(input_port)
 -- XXX potentially find better spawn locatiosn
 local spawn_pos = self.spawn_locations[spawn_idx]:clone()
 local spawn=cls_spawn.init(spawn_pos, input_port)
 spawn_idx = (spawn_idx%#self.spawn_locations)+1
 return spawn
end

function cls_room:tile_at(pos)
 local v=self.pos+pos
 return mget(v.x,v.y)
end

function solid_at(bbox)
 if bbox.aax<0
  or bbox.bbx>room.dim.x*8
  or bbox.aay<0
  or bbox.bby>room.dim.y*8 then
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
 for i=bb.aax,bb.bbx do
  for j=bb.aay,bb.bby do
   if fget(tile_at(i,j),flag) then
    return true,v2(i,j)
   end
  end
 end
 return false
end
