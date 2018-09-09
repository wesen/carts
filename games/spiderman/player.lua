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
 self.previous_tether=nil
 self.flip=v2(false,false)
end)

function cls_player:get_closest_tether()
 local d=10000
 local res=nil
 local dir=self.spd.x>0 and 1 or -1
 if (btn(0)) dir=-1
 if (btn(1)) dir=1
 for tether in all(tethers) do
  if (dir==1 and tether.pos.x>self.pos.x) or
   (dir==-1 and tether.pos.x<self.pos.x) then
    local _d=abs(self.pos.x-tether.pos.x)
    if _d<d and d>50 and tether!=self.previous_tether then
     res=tether
     d=_d
    end
  end
 end
 if (res==nil) res=tethers[1]
 return res
end

function cls_player:draw()
 if self.current_tether!=nil then
  line(self.pos.x,self.pos.y,
  self.current_tether.pos.x,self.current_tether.pos.y,7)
 end

 local tether=self.current_tether

 if(self.pos.y>=118) then
  --printh("stopped on ground")
  spr(17,self.pos.x,self.pos.y,1,1,false, false)

 elseif(true) then
  if (self.spd.y < .2 and self.spd.x < .2 and (tether==nil or self.pos.y > tether.pos.y)) then
   --printh("player is idle)
   spr(37,self.pos.x-5,self.pos.y-1,1,1,false, false)

  elseif (self.spd.y < .4 and self.prev.x > self.pos.x) then
   --printh("player was moving left")
   spr(35,self.pos.x-3,self.pos.y-2,1,1,true, false)

  elseif (self.spd.y < .4 and self.prev.x < self.pos.x) then
   --printh("player was moving right")
   spr(35,self.pos.x-4,self.pos.y-2,1,1,false, false)

  elseif (self.spd.x < .4 and self.prev.y < self.pos.y
    and tether!=nil and self.pos.x <= tether.pos.x) then
   --printh("player was moving down tether to right")
   spr(33,self.pos.x-5,self.pos.y-3,1,1,false,false)

  elseif (self.spd.x < .4 and self.prev.y < self.pos.y
   and tether!=nil and self.pos.x > tether.pos.x) then
   --printh("player was moving down and tehter to left")
   spr(33,self.pos.x-2,self.pos.y-3,1,1,true, false)

  elseif (self.spd.x < .4 and self.prev.y > self.pos.y
  and tether!=nil and self.pos.x <= tether.pos.x) then
   --printh("player was moving up, tether to the right")
   -- spr(33,self.pos.x-5,self.pos.y-4,1,1,false,true)
   spr(36,self.pos.x-5,self.pos.y-2,1,1,true, false)
  elseif (self.spd.x < .4 and self.prev.y > self.pos.y
  and tether!=nil and self.pos.x > tether.pos.x) then
   --printh("player was moving up, tether to the left")
   -- spr(33,self.pos.x-2,self.pos.y-4,1,1,true,true)
   spr(36,self.pos.x-2,self.pos.y-2,1,1,false, false)
  elseif (self.prev.x > self.pos.x and self.prev.y < self.pos.y) then
   --printh("player was moving down and left")
   spr(34,self.pos.x-1,self.pos.y-2,1,1,true, false)
  elseif (self.prev.x < self.pos.x and self.prev.y < self.pos.y) then
   --printh("player was moving down and right")
   spr(34,self.pos.x-6,self.pos.y-2,1,1,false, false)
  elseif (self.prev.x > self.pos.x and self.prev.y > self.pos.y) then
   -- printh("player was moving up and left")
   spr(36,self.pos.x-5,self.pos.y-2,1,1,true, false)
  elseif (self.prev.x < self.pos.x and self.prev.y > self.pos.y) then
   --printh("player was moving up and right")
   spr(36,self.pos.x-2,self.pos.y-2,1,1,false, false)
  end

 end
end

function cls_player:update()
 local _gravity=gravity

 -- adjust gravity
 if (self.mode==mode_free) _gravity*=0.8
 if (self.mode==mode_swing) _gravity*=1.5
 self.spd.y=appr(self.spd.y,maxfall,_gravity)

 self.prev.x=self.pos.x
 self.prev.y=self.pos.y

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

 if (btn(4) and not prevbtn) or self.pos.y>=100 then
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
   self.previous_tether=self.current_tether
   self.current_tether=nil
  end

  local _normal_tether_length=normal_tether_length
  if self.mode==mode_pulling then
   _normal_tether_length=max(self.tether_length,normal_tether_length)
   self.tether_length-=3
  end

  if self.mode!=mode_free then
   if self.mode==mode_pulling and l<normal_tether_length then
    -- printh("Switch to swinging l "..tostr(l))
    self.mode=mode_swinging
   end

   if l>_normal_tether_length then
    local _factor=_normal_tether_length/l
    -- printh("mode "..tostr(self.mode).." normal_tether_length "..tostr(_normal_tether_length))
    -- printh("resize tether pull by "..tostr(_factor).." l "..tostr(l))
    v*=_factor
    self.pos=tether.pos+v
    self.spd=self.pos-self.prev
   end
  end
 end

 local vs=self.spd:magnitude()
 local max_v=7
 self.spd.y=mid(-5,self.spd.y,4)
 if (vs>max_v) self.spd*=max_v/vs

 prevbtn=btn(4)
end
