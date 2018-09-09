cls_player=subclass(cls_actor,function(self)
 self.pos=v2(10,80)
 self.fly_button=cls_button.init(btn_fly,30)
 -- self.fire_button=cls_button.init(btn_fire,30)
 self.spd=v2(0,0)
 self.hitbox=hitbox(v2(0,0),v2(8,8))
 self.is_solid=true
 self.spr=35
 self.flip=v2(false,false)
 self.prev_input=0
 self.weight=0.5
 del(actors,self)
end)

function cls_player:draw()
 palt(7,true)
 spr(self.spr,self.pos.x,self.pos.y,1,1,not self.flip.x,self.flip.y)
 palt()
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
 local gravity=0.12*self.weight

 self.spr=35
 if self.fly_button.is_down then
  if self.fly_button:is_held() or self.fly_button:was_just_pressed() then
   self.spr=36
   self.spd.y=-1.2
   self.fly_button.hold_time+=1
  end
 end

 self.spd.y=appr(self.spd.y,maxfall,gravity)
 local dir=self.flip.x and -1 or 1

 self:move(self.spd)

 if input!=self.prev_input and input!=0 then
  printh("Update input")
  self.flip.x=input==-1
 end
 self.prev_input=input

 if btnp(btn_fire) then
  printh("FIRE")
  cls_projectile.init(self.pos+v2(0,8),v2(self.spd.x+dir*0.5,0))
 end
end
