spr_vanishing_platform=96

vp_state_visible=0
vp_state_vanishing=1
vp_state_vanished=2

cls_vanishing_platform=class(function(self,pos)
 self.x=pos.x
 self.y=pos.y
 self.aax=pos.x
 self.aay=pos.y+0.5
 self.bbx=self.aax+8
 self.bby=self.aay+3.5
 self.state=vp_state_visible
 self.spr=spr_vanishing_platform
 add(environments,self)
end)
tiles[spr_vanishing_platform]=cls_vanishing_platform

function cls_vanishing_platform:collides_with(o,x,y)
 return self.state!=vp_state_vanished and do_bboxes_collide_offset(o,self,x,y)
end

function cls_vanishing_platform:draw()
 if (self.state!=vp_state_vanished) spr(self.spr,self.x,self.y)
end

function cls_vanishing_platform:update()
 if self.state==vp_state_visible then
  for p in all(players) do
   if do_bboxes_collide_offset(p,self,0,1) then
    self.state=vp_state_vanishing
    add_cr(function()
     cr_wait_for(.2)
     self.spr=spr_vanishing_platform+1
     cr_wait_for(.5)
     self.spr=spr_vanishing_platform+2
     cr_wait_for(.5)
     self.state=vp_state_vanished
     cr_wait_for(2)
     self.state=vp_state_visible
     self.spr=spr_vanishing_platform
    end)
   end
  end
 end
end
