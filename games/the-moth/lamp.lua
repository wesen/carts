spr_lamp_off=98
spr_lamp_on=96

lamps={}
switches={}

cls_lamp=class(typ_lamp,function(self,pos,tile)
 self.pos=pos
 self.is_on=tile==spr_lamp_on
 add(actors,self)
end)

tiles[spr_lamp_off]=cls_lamp
tiles[spr_lamp_on]=cls_lamp

function cls_lamp:draw()
 local spr_=self.is_on and spr_lamp_on or spr_lamp_off
 spr(spr_,self.pos.x,self.pos.y,2,2)
end

spr_switch_on=69
spr_switch_off=70

switch_targets={}

cls_lamp_switch=class(typ_lamp_switch,function(self,pos,tile)
 self.pos=pos
 self.hitbox=hitbox(v2(-3,-3),v2(11,11))
 self.is_solid=false
 self.is_on=tile==spr_switch_on
 add(actors,self)
end)

tiles[spr_switch_off]=cls_lamp_switch
tiles[spr_switch_on]=cls_lamp_switch

function cls_lamp_switch:update()
end

function cls_lamp_switch:draw()
 local spr_=self.is_on and spr_switch_on or spr_switch_off
 spr(spr_,self.pos.x,self.pos.y)
end