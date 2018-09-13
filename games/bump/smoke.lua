spr_wall_smoke=54
spr_ground_smoke=51
spr_full_smoke=48
spr_ice_smoke=57
spr_slide_smoke=60

cls_smoke=class(function(self,pos,start_spr,dir)
 self.x=pos.x+mrnd(1)
 self.y=pos.y
 add(particles,self)
 self.flip_x=maybe()
 self.spr=start_spr
 self.start_spr=start_spr
 self.spd_x=dir*(0.3+rnd(0.2))
end)

function cls_smoke:update()
 self.x+=self.spd_x
 self.spr+=0.2
 if (self.spr>self.start_spr+3) del(particles,self)
end

function cls_smoke:draw()
 spr(self.spr,self.x,self.y,1,1,self.flip_x,false)
end
