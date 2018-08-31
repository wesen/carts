spr_lamp_off=98
spr_lamp_on=96
spr_lamp2_off=106
spr_lamp2_on=104

spr_lamp_nr_base=84

cls_lamp=subclass(typ_lamp,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.is_on=(tile)%4==0
 self.is_solid=false
 -- lookup number in tile below
 self.nr=room:tile_at(self.pos/8+v2(0,1))-spr_lamp_nr_base
 self.spr=tile-(self.is_on and 0 or 2)
 self.light_position=self.pos+v2(6,6)
 add(room.lamps,self)
end)

tiles[spr_lamp_off]=cls_lamp
tiles[spr_lamp_on]=cls_lamp
tiles[spr_lamp2_off]=cls_lamp
tiles[spr_lamp2_on]=cls_lamp

function cls_lamp:update()

 -- flickering light logic
 if self.timer!=nil then
  local tick=frame%self.timer[1]
  if tick==0 or tick==self.timer[2] then
   self.is_on=not self.is_on
  end
 end
end

function cls_lamp:draw()
 local spr_=self.spr+(self.is_on and 0 or 2)
 spr(spr_,self.pos.x,self.pos.y,2,2)
end

spr_switch_on=69
spr_switch_off=70

cls_lamp_switch=subclass(typ_lamp_switch,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.hitbox=hitbox(v2(-2,-2),v2(12,12))
 self.is_solid=false

 -- lookup number in tile above
 self.nr=room:tile_at(self.pos/8+v2(0,-1))-spr_lamp_nr_base
 self.is_on=tile==spr_switch_on
 self.player_near=false
 add(room.switches,self)
end)

tiles[spr_switch_off]=cls_lamp_switch
tiles[spr_switch_on]=cls_lamp_switch

function cls_lamp_switch:update()
 self.player_near=player!=nil and player:collides_with(self)
 if self.player_near and btnp(btn_action) then
  room:handle_switch_toggle(self)
 end
end

function cls_lamp_switch:draw()
 local spr_=self.is_on and spr_switch_on or spr_switch_off
 spr(spr_,self.pos.x,self.pos.y)
 -- self:bbox():draw(7)
end

function cls_lamp_switch:draw_text()
 if self.player_near and should_blink(24) and player.on_ground then
  palt(0,false)
  bstr("\x97",self.pos.x-1,self.pos.y-8,0,6)
  palt()
 end
end