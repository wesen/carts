mode_swinging=1
mode_free=2
mode_pulling=3

maxfall=5
gravity=0.20
normal_tether_length=10

prevbtn=false

player=nil

cls_player=class(function(self,pos)
 self.pos=pos
 self.spd=v2(.2,2)
 self.mode=mode_free
 self.tether_length=0
 self.prev=v2(10,28)
 self.frame_sensitive=5
 self.current_tether=nil
 self.flip=v2(false,false)
end)

function cls_player:get_closest_tether()
 return tethers[1]
end

function cls_player:draw()
 if self.current_tether!=nil then
  line(self.pos.x,self.pos.y,
  self.current_tether.pos.x,self.current_tether.pos.y,7)
 end

 local spr_=33

 local dir=self.prev.x>self.pos.x and -1 or
 self.prev.x<self.pos.x and 1 or 0
 local is_idle=self.spd:sqrmagnitude()<.2
 and self.current_tether!=nil
 and self.pos.y>self.current_tether.pos.y

 -- on ground
 if (self.pos.y>=118) spr_=17
 if (is_idle) spr_=37

 if abs(self.spd.y)<.3 then
  if dir==-1 then
   spr_=35
  end
 else
 end

 spr(spr_,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)

 --[[
elseif (obj.sy < .4 and obj.prevx > obj.x) then
--printh("player was moving left")
spr(35,obj.x-3,obj.y-2,1,1,true, false)

elseif (obj.sy < .4 and obj.prevx < obj.x) then
--printh("player was moving right")
spr(35,obj.x-4,obj.y-2,1,1,false, false)

elseif (obj.sx < .4 and obj.prevy < obj.y and obj.x <= tether.x) then
--printh("player was moving down tether to right")
spr(33,obj.x-5,obj.y-3,1,1,false,false)

elseif (obj.sx < .4 and obj.prevy < obj.y and obj.x > tether.x) then
--printh("player was moving down and tehter to left")
spr(33,obj.x-2,obj.y-3,1,1,true, false)

elseif (obj.sx < .4 and obj.prevy > obj.y and obj.x <= tether.x) then
--printh("player was moving up, tether to the right")
-- spr(33,obj.x-5,obj.y-4,1,1,false,true)
spr(36,obj.x-5,obj.y-2,1,1,true, false)
elseif (obj.sx < .4 and obj.prevy > obj.y and obj.x > tether.x) then
--printh("player was moving up, tether to the left")
-- spr(33,obj.x-2,obj.y-4,1,1,true,true)
spr(36,obj.x-2,obj.y-2,1,1,false, false)




elseif (obj.prevx > obj.x and obj.prevy < obj.y) then
--printh("player was moving down and left")
spr(34,obj.x-1,obj.y-2,1,1,true, false)

elseif (obj.prevx < obj.x and obj.prevy < obj.y) then
--printh("player was moving down and right")
spr(34,obj.x-6,obj.y-2,1,1,false, false)

elseif (obj.prevx > obj.x and obj.prevy > obj.y) then
-- printh("player was moving up and left")
spr(36,obj.x-5,obj.y-2,1,1,true, false)

elseif (obj.prevx < obj.x and obj.prevy > obj.y) then
--printh("player was moving up and right")
spr(36,obj.x-2,obj.y-2,1,1,false, false)
end
]]
end

function cls_player:update()
 local _gravity=gravity

 -- adjust gravity
 if (self.mode==mode_free) _gravity*=0.8
 if (self.mode==mode_swing) _gravity*=1.5
 self.spd.y=appr(self.spd.y,maxfall,_gravity)

 self.prev.x=self.pos.x
 self.prev.y=self.pos.y

 -- world boundaries
 if (self.pos.x<=0) self.pos.x=127
 if (self.pos.x>127) self.pos.x=0
 if (self.pos.y<=0) self.pos.y=117  --if (self.pos.y<=0) self.pos.y=115 --edited

 -- bounce on floor
 if self.pos.y>=118 then --if self.pos.y>118 then  --edited
  self.pos.y=118
  --self.spd.y=-self.spd.y --commented out --edited
  self.spd.x*=0.95
  self.spd.y=0 --self.spd.y*=0.3 --edited
  if (abs(self.spd.y)<0.5) self.spd.y=0
  if (abs(self.spd.x)<0.5) self.spd.x=0
 end

 self.pos.y+=self.spd.y
 self.pos.x+=self.spd.x

 self.pos.x=mid(0,self.pos.x,128)
 self.pos.y=mid(0,self.pos.y,128)


 if btn(4) and not prevbtn then
  if self.mode==mode_free then
   self.mode=mode_pulling
   self.current_tether=self:get_closest_tether()
   local l=(self.pos-self.current_tether.pos):magnitude()
   self.tether_length=l
  end
 end

 if self.current_tether!=nil then
  local tether=self.current_tether

  local v=self.pos-tether.pos
  local l=v:magnitude()

  if not btn(4) and self.mode!=mode_free then
   self.mode=mode_free
  end

  local _normal_tether_length=normal_tether_length
  if self.mode==mode_pulling then
   _normal_tether_length=max(self.tether_length,normal_tether_length)
   self.tether_length-=3
  end

  if self.mode!=mode_free then
   if self.mode==mode_pulling and l<normal_tether_length then
    self.mode=mode_swinging
   end

   if l>_normal_tether_length then
    v*=_normal_tether_length/l
    self.pos=tether.pos+v
    self.spd=self.pos-self.prev
   end
  end
 end

 prevbtn=btn(4)
end
