cls_player=subclass(cls_actor,function(self)
 self.pos=v2(10,80)
 self.fly_button=cls_button.init(btn_fly,30)
 self.spd=v2(0,0)
 self.hitbox=hitbox(v2(0,0),v2(8,8))
 self.is_solid=true
 del(actors,self)
end)

function cls_player:draw()
 rectfill(self.pos.x,self.pos.y,self.pos.x+8,self.pos.y+8,7)
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

 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel)
 else
  self.spd.x=appr(self.spd.x,0,decel)
 end

 local maxfall=2
 local gravity=0.12

 if self.fly_button.is_down then
  if self.fly_button:is_held() or self.fly_button:was_just_pressed() then
   self.spd.y=-1.2
   self.fly_button.hold_time+=1
  end
 end

 self.spd.y=appr(self.spd.y,maxfall,gravity)

 self:move(self.spd)
end
