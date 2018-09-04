cls_player=class(function(self)
 self.pos=v2(64,16)
 self.spd=v2(0,0)
 self.spr=1
 self.flip=v2(false,false)

 self.hitbox=hitbox(v2(2,0),v2(4,8))
 self.jump_button=cls_button.init(btn_jump)
 self.on_ground=true
 self.ground_debouncer=cls_debouncer.init(ground_grace_interval)
 self.prev_input=0

 self.ghosts={}
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
 local dark=0
 for ghost in all(self.ghosts) do
  dark+=10
  darken(dark)
  spr(self.spr,ghost.x,ghost.y,1,1,self.flip.x,self.flip.y)
 end
 pal()

 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end

function cls_player:smoke(spr,dir)
 return cls_smoke.init(self.pos,spr,dir)
end

function cls_player:update()
 self.jump_button:update()

 -- get arrow input
 local input=btn(btn_right) and 1
    or (btn(btn_left) and -1
    or 0)
 if (menu.visible) input=0

 -- check if we are on ground
 local bbox_ground=self:bbox(vec_down)
 local bbox_dir=self:bbox(v2(input,0))
 local on_ground,tile=room:solid_at(bbox_ground)
 self.on_ground=on_ground
 self.ground_debouncer:debounce(on_ground)
 local on_ground_recently=self.ground_debouncer:is_on()
 local on_ice=room:tile_flag_at(bbox_ground,flg_ice)

 -- compute x speed by acceleration / friction
 local accel_=accel
 local decel_=decel
 local maxfall_=maxfall

 if not on_ground then
  accel_=air_accel
  decel_=air_decel
 end

 if on_ice then
  accel_=ice_accel
  decel_=ice_decel
 end

 -- slow down at apex
 local gravity_=gravity
 if abs(self.spd.y)<=0.3 then
  gravity_*=0.5
 elseif self.spd.y>0 then
  -- fall down fas2er
  gravity_*=2
 end

 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel_)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel_)
 else
  self.spd.x=appr(self.spd.x,0,decel_)
 end

 if self.spd.x!=0 then
  self.flip.x=self.spd.x<0
 end

 -- wall slide
 local is_wall_sliding=false
 if input!=0 and room:solid_at(bbox_dir) and not on_ground and self.spd.y>0 then
  is_wall_sliding=true
  maxfall_=wallslide_maxfall
  if (room:tile_flag_at(bbox_dir,flg_ice)) maxfall_=wallslide_ice_maxfall
  local smoke_dir = self.flip.x and .3 or -.3
  if maybe(.1) then
    local smoke=self:smoke(spr_wall_smoke,smoke_dir)
    smoke.flip.x=self.flip.x
  end
 end

 -- compute Y speed
 if self.jump_button.is_down then
  if self.jump_button:was_recently_pressed() and on_ground_recently then
   self:smoke(spr_ground_smoke,0)
   self.spd.y=-jump_spd
   self.ground_debouncer:clear()
  end
 end
 if (not on_ground) self.spd.y=appr(self.spd.y,maxfall_,gravity_)

 -- actually move
 self:move_x(self.spd.x)
 self:move_y(self.spd.y)

 -- log values
 logger:add("spd.x",self.spd.x)
 logger:add("spd.y",self.spd.y)
 logger:add("pos.x",self.pos.x)
 logger:add("pos.y",self.pos.y)

 -- compute graphics
 if input!=self.prev_input and input!=0 and on_ground then
  if on_ice then
   self:smoke(spr_ice_smoke,-input)
  else
   -- smoke when changing directions
   self:smoke(spr_ground_smoke,-input)
  end
 end

  -- add ice smoke when sliding on ice (after releasing input)
 if on_ice and input==0 and abs(self.spd.x)>0.3
    and (maybe(0.15) or self.prev_input!=0) then
   self:smoke(spr_slide_smoke,-input)
 end

 self.prev_input=input

 -- choosing sprite
 if input==0 then
  self.spr=1
 elseif not on_ground then
  self.spr=3
 else
  self.spr=1+flr(frame/4)%3
 end

 if (not on_ground and frame%2==0) insert(self.ghosts,self.pos:clone(),7)
 if ((on_ground or #self.ghosts>7)) popend(self.ghosts)
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
