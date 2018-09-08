cls_room=class(typ_room,function(self,r)
 self.pos=r.pos
 self.dim=r.dim
 self.player_spawn=nil
 self.moth_spawn=nil
 self.lamps={}
 self.switches={}
 self.opaque_tiles={}

 room=self

 -- initialize tiles
 for i=0,self.dim.x-1 do
  for j=0,self.dim.y-1 do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   -- add solid tile bboxes for collision check
   if fget(tile,flg_opaque) then
    add(self.opaque_tiles,bbox(p*8,p*8+v2(8,8)))
   end
   if (tile==spr_spawn_point) self.player_spawn=p*8
   if (tile==spr_moth) self.moth_spawn=p*8
   local t=tiles[tile]
   if (t!=nil) t.init(p*8,tile)
  end
 end

  -- configuring special lights from config
  local l=levels[game.current_level]
  for timer in all(l.timer_lights) do
   for lamp in all(self.lamps) do
    if lamp.nr==timer[1] then
     lamp.timer={timer[2],timer[3]}
    end
   end
  end

  for timer in all(l.countdown_lights) do
   for lamp in all(self.lamps) do
    if lamp.nr==timer[1] then
     lamp.countdown=timer[2]
    end
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
 palt(14,true)
 palt(0,false)
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,128)
 palt()
end

function cls_room:spawn_player()
 local spawn=cls_spawn.init(self.player_spawn:clone())
 main_camera:set_target(spawn)
end

function cls_room:handle_switch_toggle(switch)
 self.player_spawn=switch.pos

 switch.is_on=not switch.is_on

 for lamp in all(self.lamps) do
  if lamp.nr==switch.nr then
   lamp:toggle()
  end
 end

 -- sync all the other switches on the same circuit
 for s_ in all(self.switches) do
  if (s_.nr==switch.nr) s_.is_on=switch.is_on
 end
 if switch.is_on then
  sfx(30)
 else
  sfx(31)
 end
end

-- this is a bit dirty because every lamp on the circuit will sync the switches
function cls_room:handle_lamp_off(lamp)
 lamp:toggle()
 for s_ in all(self.switches) do
  if (s_.nr==lamp.nr) s_.is_on=lamp.is_on
 end
 for l in all(self.lamps) do
  if (l.nr==lamp.nr and l!=lamp) l:toggle()
 end
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
