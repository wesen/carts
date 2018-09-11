function v_idx(pos)
 return pos.x+pos.y*128
end

cls_room=class(function(self,pos,dim)
 self.x=pos.x
 self.y=pos.y
 self.dim_x=dim.x
 self.dim_y=dim.y
 self.spawn_locations={}
 self.aax=0
 self.aay=0
 self.bbx=self.dim_x*8
 self.bby=self.dim_y*8

 -- initialize tiles
 for i=0,self.dim_x-1 do
  for j=0,self.dim_y-1 do
   local tile=self:tile_at(i,j)
   local p={x=i*8,y=j*8}
   if tile==spr_spawn_point then
    add(self.spawn_locations,p)
   end
   local t=tiles[tile]
   if t!=nil then
    local a=t.init(p)
    a.tile=tile
   end
  end
 end
end)

function cls_room:draw()
 map(self.x,self.y,0,0,self.dim_x,self.dim_y,flg_solid+1)
end

function cls_room:spawn_player(input_port)
 -- xxx potentially find better spawn locatiosn
 local spawn_pos = self.spawn_locations[spawn_idx]
 local spawn=cls_spawn.init(spawn_pos, input_port)
 spawn_idx = (spawn_idx%#self.spawn_locations)+1
 return spawn
end

function cls_room:tile_at(x,y)
 return mget(self.x+x,self.y+y)
end

function solid_at(bbox)
 if bbox.aax<0
  or bbox.bbx>room.bbx
  or bbox.aay<0
  or bbox.bby>room.bby then
   return true
 else
  return tile_flag_at(bbox,flg_solid)
 end
end

function ice_at(bbox)
 return tile_flag_at(bbox,flg_ice)
end

function tile_at(x,y)
 return room:tile_at(x,y)
end

function tile_flag_at(bbox,flag)
 local bb=bbox:to_tile_bbox()
 local rx=room.x
 local ry=room.y
 for i=bb.aax,bb.bbx do
  for j=bb.aay,bb.bby do
   if fget(mget(rx+i,ry+j),flag) then
    return true
   end
  end
 end
 return false
end
