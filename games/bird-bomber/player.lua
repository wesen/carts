cls_player=subclass(cls_actor,function(self)
 cls_actor._ctr(self,10,80)
 self.fly_button=cls_button.init(btn_fly,30)
 -- self.fire_button=cls_button.init(btn_fire,30)
 self.is_solid=true
 self.spr=35
 self.fliph=false
 self.flipv=false
 self.prev_input=0
 self.weight=0.5
 del(glb_actors,self)
end)

function cls_player:draw()
 palt(7,true)
 spr(self.spr,self.x,self.y,1,1,not self.fliph,self.flipv)
 palt()
 rect(self.aax,self.aay,self.bbx,self.bby,8)
end

function cls_player:update()
 local input=btn(btn_right) and 1
    or (btn(btn_left) and -1
    or 0)

 self.fly_button:update()

 -- x movement
 local maxrun=1
 local accel=0.1
 local decel=0.01

 if abs(self.spdx)>maxrun then
  self.spdx=appr(self.spdx,sign(self.spdx)*maxrun,decel)
 elseif input != 0 then
  self.spdx=appr(self.spdx,input*maxrun,accel)
 else
  self.spdx=appr(self.spdx,0,decel)
 end

 local maxfall=2
 local gravity=0.12*self.weight

 self.spr=35
 if self.fly_button.is_down then
  if self.fly_button:is_held() or self.fly_button:was_just_pressed() then
   self.spr=36
   self.spdy=-1.2
   self.fly_button.hold_time+=1
  end
  if (self.fly_button:was_just_pressed()) sfx(14)
 end

 self.spdy=appr(self.spdy,maxfall,gravity)
 local dir=self.fliph and -1 or 1


 self:move_x(self.spdx)
 self:move_y(self.spdy)

 if input!=self.prev_input and input!=0 then
  self.fliph=input==-1
 end
 self.prev_input=input

 if btnp(btn_fire) then
  cls_projectile.init(self.x,self.y+8,self.spdx+dir*0.5,0)
  sfx(16)
 end
end
