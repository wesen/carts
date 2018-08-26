function v_idx(pos)
 return pos.x+pos.y*16
end

cls_room=class(typ_room,function(self,pos)
 self.pos=pos
 self.spawn_locations={}
 self.gore={}

 for i=0,15 do
  for j=0,15 do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   if fget(tile,flg_solid) then
    self.gore[v_idx(p)]=0
   end
   if tile==spr_spawn_point then
    add(self.spawn_locations,p*8)
   end
   local t=tiles[tile]
   if (t!=nil) t.init(p*8)
  end
 end
end)

function cls_room:draw()
 map(self.pos.x*16,self.pos.y*16,0,0,16,16,flg_solid+1)
 for i=0,15 do
  for j=0,15 do
   local v=v_idx(v2(i,j))
   local g=self.gore[v]
   if g!=nil then
    self.gore[v]-=0.05
    if g>10 then
     spr(83,i*8,j*8)
    elseif g>5 then
     spr(82,i*8,j*8)
    elseif g>0 then
     spr(81,i*8,j*8)
    else
     self.gore[v]=0
    end
   end
  end
 end
end

function cls_room:spawn_player()
 cls_spawn.init(self.spawn_locations[1]:clone())
end

function cls_room:tile_at(pos)
 local v=self.pos*16+pos
 return mget(v.x,v.y)
end

function solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>128
  or bbox.aa.y<0
  or bbox.bb.y>128 then
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