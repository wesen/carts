function v_idx(pos)
 return pos.x+pos.y*128
end

function gore_idx(pos,dir)
 return v_idx(pos)*4+dir
end

cls_room=class(typ_room,function(self,pos,dim)
 self.pos=pos
 self.dim=dim
 self.spawn_locations={}
 self.gore={}

 for i=0,self.dim.x do
  for j=0,self.dim.y do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   if fget(tile,flg_solid) then
    for dir=-1,2 do
     self.gore[gore_idx(p,dir)]=0
    end
   end
   if tile==spr_spawn_point then
    add(self.spawn_locations,p*8)
   end
   local t=tiles[tile]
   if (t!=nil) t.init(p*8)
  end
 end
end)

function cls_room:get_gore(tile,dir)
 local v=gore_idx(tile,dir)
 local g=self.gore[v]
 if (g==nil) g=0
 return g
end

function cls_room:get_friction(tile,dir)
 local accel=0.3
 local decel=0.2

 local g=self:get_gore(tile,dir)
 if g>10 then
  accel=0.08
  decel=0.02
 elseif g>5 then
  accel=0.15
  decel=0.07
 else
  accel=0.2
  decel=0.15
 end
 if (fget(self:tile_at(tile),flg_ice)) accel,decel=min(accel,0.1),min(decel,0.03)

 return accel,decel
end

function cls_room:draw()
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
 -- draw gore
 for i=0,self.dim.x do
  for j=0,self.dim.y do
   for dir=-1,2 do
    local v=gore_idx(v2(i,j),dir)
    local g=self.gore[v]
    if g!=nil then
     self.gore[v]=min(15,self.gore[v]-0.02)
     if g>10 then
      rspr(83,i*8,j*8,dir)
     elseif g>5 then
      rspr(82,i*8,j*8,dir)
     elseif g>0 then
      rspr(81,i*8,j*8,dir)
     else
      self.gore[v]=0
     end
    end
   end
  end
 end
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