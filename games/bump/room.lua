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
   local tile=mget(self.x+i,self.y+j)
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
 map(self.x,self.y,0,0,self.dim_x,self.dim_y,flg_solid+1+16)
end

function cls_room:spawn_player(input_port)
 -- xxx potentially find better spawn locatiosn
 local spawn_pos = self.spawn_locations[spawn_idx]
 local spawn=cls_spawn.init(spawn_pos, input_port)
 spawn_idx = (spawn_idx%#self.spawn_locations)+1
 connected_players[input_port]=true
 return spawn
end

function solid_at_offset(bbox,x,y)
 if bbox.aax+x<0
  or bbox.bbx+x>room.bbx
  or bbox.aay+y<0
  or bbox.bby+y>room.bby then
   return true,nil
 end
 if (tile_flag_at_offset(bbox,flg_solid,x,y)) return true,nil
 for e in all(environments) do
  if (e:collides_with(bbox,x,y)) return true,e
 end
 return false,nil
end

function ice_at_offset(bbox,x,y)
 return tile_flag_at_offset(bbox,flg_ice,x,y)
end

function tile_flag_at_offset(bbox,flag,x,y)
 local aax=max(0,flr((bbox.aax+x)/8))+room.x
 local aay=max(0,flr((bbox.aay+y)/8))+room.y
 local bbx=min(room.dim_x,(bbox.bbx+x-1)/8)+room.x
 local bby=min(room.dim_y,(bbox.bby+y-1)/8)+room.y
 for i=aax,bbx do
  for j=aay,bby do
   if fget(mget(i,j),flag) then
    return true
   end
  end
 end
 return false
end
