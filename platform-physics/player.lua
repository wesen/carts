cls_player=class(function(self)
 self.pos=v2(64,48)
 self.spd=v2(0,0)
 self.spr=1
 self.flip=v2(false,false)

 self.hitbox=hitbox(v2(2,0),v2(4,8))
 self.on_ground=true
end)

function cls_player:str()
 return "player["..tostr(self.id)..",t:"..tostr(self.typ).."]"
end

function cls_player:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return self.hitbox:to_bbox_at(self.pos+offset)
end

function cls_player:is_solid_at(offset)
 return room:solid_at(self:bbox(offset))
end

function cls_player:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

function cls_player:update()
 local input=btn(btn_right) and 1
    or (btn(btn_left) and -1
    or 0)

 local on_ground,tile=self:is_solid_at(vec_down)
 self.on_ground=on_ground

 -- compute X speed
 if input!=0 then
  self.spd.x=input
 end

 if self.spd.x!=0 then
  self.flip.x=self.spd.x<0
 end

 -- compute Y speed
 local maxfall=2
 local gravity=0.12
 if (not on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

 self:move_x(self.spd.x)
 self:move_y(self.spd.y)

 if input==0 then
  self.spr=1
 else
  self.spr=1+flr(frame/4)%3
 end
end

function cls_player:move_x(amount)
 while abs(amount)>0 do
  local step=amount
  if (abs(amount)>1) step=sign(amount)
  amount-=step
  if not self:is_solid_at(v2(step,0)) then
   self.pos.x+=step
  else
   self.spd.x=0
   break
  end
 end
end

function cls_player:move_y(amount)
 while abs(amount)>0 do
  local step=amount
  if (abs(amount)>1) step=sign(amount)
  amount-=step
  if not self:is_solid_at(v2(0,step)) then
   self.pos.y+=step
  else
   self.spd.y=0
   break
  end
 end
end
