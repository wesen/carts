player=nil

cls_player=subclass(typ_player,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 -- player is a special actor
 del(actors,self)
 player=self
 main_camera:set_target(self)

 self.flip=v2(false,false)
 self.jump_button=cls_button.init(btn_jump)
 self.spr=1
 self.hitbox=hitbox(v2(2,0),v2(4,8))
 self.atk_hitbox=hitbox(v2(1,0),v2(6,4))

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0
 self.step_count=0

 self.ghosts={}
 self.on_ground=true

end)

function cls_player:smoke(spr,dir)
 return cls_smoke.init(self.pos,spr,dir)
end

function cls_player:kill()
 make_gore_explosion(self.pos)
 player=nil
 main_camera:add_shake(8)
 sfx(0)
 add_cr(function()
  wait_for(1)
  room:spawn_player()
 end)
end

function cls_player:update()
 -- from celeste's player class
 local input=btn(btn_right) and 1
    or (btn(btn_left) and -1
    or 0)

 self.jump_button:update()

 local maxrun=1
 local accel=0.3
 local decel=0.2

 local ground_bbox=self:bbox(vec_down)
 local on_ground,tile=solid_at(ground_bbox)
 self.on_ground=on_ground
 local on_ice=ice_at(ground_bbox)

 if on_ground then
  self.on_ground_interval=ground_grace_interval
 elseif self.on_ground_interval>0 then
  self.on_ground_interval-=1
 end
 local on_ground_recently=self.on_ground_interval>0

 if not on_ground then
  accel=0.2
  decel=0.1
 else
  if tile!=nil then
   accel,decel=room:get_friction(tile,dir_down)
  end

  if input!=self.prev_input and input!=0 then
   self.step_count=0
   if on_ice then
    self:smoke(spr_ice_smoke,-input)
   else
    -- smoke when changing directions
    self:smoke(spr_ground_smoke,-input)
    sfx(34)
   end
  end

  -- add ice smoke when sliding on ice (after releasing input)
  if input==0 and abs(self.spd.x)>0.3
     and (maybe(0.15) or self.prev_input!=0) then
   if on_ice then
    self:smoke(spr_slide_smoke,-input)
   end
  end
 end
 self.prev_input=input

 -- compute x speed by acceleration / friction
 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel)
 else
  self.spd.x=appr(self.spd.x,0,decel)
 end

 if self.spd.x!=0 then
  -- step sounds
  if input != 0 and on_ground then
   self.step_count+=1
   if self.step_count==22 then
    sfx(36)
    self.step_count=0
   elseif self.step_count==15 then
    sfx(37)
   elseif self.step_count==7 then
    sfx(33)
   end
  end

  -- orient sprite
  self.flip.x=self.spd.x<0
 end

 -- y movement
 local maxfall=2
 local gravity=0.12

 -- slow down at apex
 if abs(self.spd.y)<=0.15 then
  gravity*=0.5
 elseif self.spd.y>0 then
  -- fall down fas2er
  gravity*=2
 end

 -- wall slide
 local is_wall_sliding=false
 if input!=0 and self:is_solid_at(v2(input,0))
    and not on_ground and self.spd.y>0 then
  is_wall_sliding=true
  maxfall=0.4
  if (ice_at(self:bbox(v2(input,0)))) maxfall=1.0
  local smoke_dir = self.flip.x and .3 or -.3
  if maybe(.1) then
    local smoke=self:smoke(spr_wall_smoke,smoke_dir)
    smoke.flip.x=self.flip.x
  end
 end

 -- jump
 if self.jump_button.is_down then
  if self.jump_button:is_held()
    or (on_ground_recently and self.jump_button:was_recently_pressed()) then
   if self.jump_button:was_recently_pressed() then
    self:smoke(spr_ground_smoke,0)
    sfx(35)
   end
   self.on_ground_interval=0
   self.spd.y=-1.0
   self.jump_button.hold_time+=1
  elseif self.jump_button:was_just_pressed() then
   -- check for wall jump
   local wall_dir=self:is_solid_at(v2(-3,0)) and -1
        or self:is_solid_at(v2(3,0)) and 1
        or 0
   if wall_dir!=0 then
    self.jump_interval=0
    self.spd.y=-1
    self.spd.x=-wall_dir*(maxrun+1)
    self:smoke(spr_wall_smoke,-wall_dir*.3)
    sfx(35)
    self.jump_button.hold_time+=1
   end
  end
 end

 if (not on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

 self:move(self.spd)

 -- animation
 if input==0 then
  self.spr=1
 elseif is_wall_sliding then
  self.spr=4
 elseif not on_ground then
  self.spr=3
 else
  self.spr=1+flr(frame/4)%3
 end

 if (not on_ground and frame%2==0) insert(self.ghosts,self.pos:clone())
 if ((on_ground or #self.ghosts>7)) popend(self.ghosts)
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

 -- not convinced by border
 -- bspr(self.spr,self.pos.x,self.pos.y,self.flip.x,self.flip.y,0)

 -- debug drawing bbox
 --[[
 local bbox=self:bbox()
 local bbox_col=8
 if self:is_solid_at(v2(0,0)) then
  bbox_col=9
 end
 bbox:draw(bbox_col)
 bbox=self.atk_hitbox:to_bbox_at(self.pos)
 bbox:draw(12)
 print(self.spd:str(),64,64)
 ]]
end

