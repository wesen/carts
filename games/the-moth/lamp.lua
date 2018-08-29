spr_lamp_off=98
spr_lamp_on=96

spr_lamp_nr_base=84

cls_lamp=subclass(typ_lamp,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.is_on=tile==spr_lamp_on
 self.is_solid=false
 -- lookup number in tile below
 self.nr=room:tile_at(self.pos/8+v2(0,1))-spr_lamp_nr_base
 add(room.lamps,self)
end)

tiles[spr_lamp_off]=cls_lamp
tiles[spr_lamp_on]=cls_lamp

function cls_lamp:draw()
 local spr_=self.is_on and spr_lamp_on or spr_lamp_off
 spr(spr_,self.pos.x,self.pos.y,2,2)
end

spr_switch_on=69
spr_switch_off=70

cls_lamp_switch=subclass(typ_lamp_switch,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.hitbox=hitbox(v2(-3,-3),v2(11,11))
 self.is_solid=false
 -- lookup number in tile above
 self.nr=room:tile_at(self.pos/8+v2(0,-1))-spr_lamp_nr_base
 self.is_on=tile==spr_switch_on
 self.player_near=false
end)

tiles[spr_switch_off]=cls_lamp_switch
tiles[spr_switch_on]=cls_lamp_switch

function cls_lamp_switch:update()
 self.player_near=player!=nil and player:collides_with(self)
 if self.player_near and btnp(btn_action) then
  self:switch()
 end
end

function cls_lamp_switch:switch()
 for lamp in all(room.lamps) do
  if lamp.nr==self.nr then
   lamp.is_on=not lamp.is_on
   self.is_on=lamp.is_on
  end
 end
end

function cls_lamp_switch:draw()
 local spr_=self.is_on and spr_switch_on or spr_switch_off
 spr(spr_,self.pos.x,self.pos.y)
 if self.player_near then
  print("x - switch",self.pos.x-15,self.pos.y-10,7)
 end
end