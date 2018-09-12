players={}

player_cnt=0

cls_player=subclass(cls_actor,function(self,pos,input_port)
 cls_actor._ctr(self,pos)
 -- players are handled separately
 add(players,self)

 self.ghosts={}

 self.nr=player_cnt
 self.power_up=nil
 self.power_up_countdown=nil
 player_cnt+=1

 self.flip=v2(false,false)
 self.input_port=input_port
 self.jump_button=cls_button.init(btn_jump, input_port)
 self.spr=1
 self.hitbox={x=2,y=0.5,dimx=4,dimy=7.5}
 self.head_hitbox={x=0,y=-1,dimx=8,dimy=1}
 self.feet_hitbox={x=2,y=7,dimx=4,dimy=1}

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0

 self.is_teleporting=false
 self.on_ground=false
 self.is_bullet_time=false
 self.is_dead=false
end)

function cls_player:smoke(spr,dir)
 return cls_smoke.init(v2(self.x,self.y),spr,dir)
end

function cls_player:kill()
 del(players,self)
 del(actors,self)
 self.is_dead=true
 add_shake(3)
 sfx(1)
 if not self.is_doppelgaenger then
  room:spawn_player(self.input_port)
  for player in all(players) do
   if player.input_port==self.input_port and player.is_doppelgaenger then
    make_gore_explosion(v2(player.x,player.y))
    player:kill()
   end
  end
 end
end

function cls_player:update()
 if self.is_teleporting or self.is_bullet_time then
 else
  self:update_normal()
 end
end

function cls_player:update_normal()
 -- power up countdown
 if self.power_up_countdown!=nil then
  self.power_up_countdown-=dt
  if self.power_up_countdown<0 then
   self.power_up:on_powerup_stop(self)
   self.power_up=nil
   self.power_up_type=nil
   self.power_up_countdown=nil
  end
 end

 -- from celeste's player class
 local input=btn(btn_right, self.input_port) and 1
    or (btn(btn_left, self.input_port) and -1
    or 0)

 self.jump_button:update()

 local gravity=gravity
 local maxfall=maxfall
 local maxrun=maxrun
 local accel=0.1
 local decel=0.1
 local jump_spd=jump_spd

 if self.power_up_type==spr_power_up_superspeed then
  maxrun*=1.5
  decel*=2
  accel*=2
 elseif self.power_up_type==spr_power_up_superjump then
  jump_spd*=1.5
 elseif self.power_up_type==spr_power_up_gravitytweak then
  gravity*=0.7
  maxfall*=0.5
 end

 local ground_bbox=self:bbox(0,1)
 self.on_ground=solid_at(ground_bbox)
 local on_actor=self:is_actor_at(input,0)
 local on_ice=ice_at(ground_bbox)

 if self.on_ground then
  self.on_ground_interval=ground_grace_interval
 elseif self.on_ground_interval>0 then
  self.on_ground_interval-=1
 end
 local on_ground_recently=self.on_ground_interval>0

 if not self.on_ground then
  accel=in_air_accel
  decel=in_air_decel
 else
  if on_ice then
   accel=0.1
   decel=0.03
  end

  if input!=self.prev_input and input!=0 then
   if on_ice then
    self:smoke(spr_ice_smoke,-input)
   else
    -- smoke when changing directions
    self:smoke(spr_ground_smoke,-input)
   end
  end

  -- add ice smoke when sliding on ice (after releasing input)
  if input==0 and abs(self.spd_x)>0.3
     and (maybe(0.15) or self.prev_input!=0) then
   if on_ice then
    self:smoke(spr_slide_smoke,-input)
   end
  end
 end
 self.prev_input=input

 -- x movement
 if abs(self.spd_x)>maxrun then
  self.spd_x=appr(self.spd_x,sign(self.spd_x)*maxrun,decel)
 elseif input != 0 then
  self.spd_x=appr(self.spd_x,input*maxrun,accel)
 else
  self.spd_x=appr(self.spd_x,0,decel)
 end
 if (self.spd_x!=0) self.flip.x=self.spd_x<0

 -- y movement

 -- slow down at apex
 if abs(self.spd_y)<=apex_speed then
  gravity*=apex_gravity_factor
 elseif self.spd_y>0 then
  -- fall down fas2er
  gravity*=fall_gravity_factor
 end

 -- wall slide
 local is_wall_sliding=false
 if input!=0 and self:is_solid_at(input,0)
    and not self.on_ground and self.spd_y>0 then
  is_wall_sliding=true
  maxfall=wall_slide_maxfall
  if (ice_at(self:bbox(input,0))) maxfall=ice_wall_maxfall
  local smoke_dir = self.flip.x and .3 or -.3
  if maybe(.1) then
    local smoke=self:smoke(spr_wall_smoke,smoke_dir)
    smoke.flip_x=self.flip.x
  end
 end

 -- jump
 if self.jump_button.is_down then
  if self.jump_button:is_held()
    or (on_ground_recently and self.jump_button:was_recently_pressed()) then
   if self.jump_button:was_recently_pressed() then
    self:smoke(spr_ground_smoke,0)
    sfx(0)
   end
   self.on_ground_interval=0
   self.spd_y=-jump_spd
   self.jump_button.hold_time+=1
  elseif self.jump_button:was_just_pressed() then
   -- check for wall jump
   local wall_dir=self:is_solid_at(-3,0) and -1
        or self:is_solid_at(3,0) and 1
        or 0
   if wall_dir!=0 then
    self.jump_interval=0
    self.spd_y=-1
    self.spd_x=-wall_dir*wall_jump_spd
    self:smoke(spr_wall_smoke,-wall_dir*.3)
    self.jump_button.hold_time+=1
   end
  end
 end

 if (not self.on_ground) self.spd_y=appr(self.spd_y,maxfall,gravity)

 self:move_x(self.spd_x)
 self:move_y(self.spd_y)

 -- animation
 if input==0 then
  self.spr=1
 elseif is_wall_sliding then
  self.spr=4
 elseif not self.on_ground then
  self.spr=3
 else
  self.spr=1+flr(frame/4)%3
 end

 -- interact with players
 local feet_box=hitbox_to_bbox(self.feet_hitbox,v2(self.x,self.y))
 for player in all(players) do
  if self!=player and
  (player.power_up==nil or player.power_up!=spr_power_up_invincibility) then
   local kill_player=false

   if self.power_up_type==spr_power_up_invincibility
    and do_bboxes_collide_offset(self,player,input,0) then
    kill_player=true
   else
    -- attack
    local head_box=hitbox_to_bbox(player.head_hitbox,v2(player.x,player.y))
    local can_attack=not self.on_ground and self.spd_y>0

    if (feet_box:collide(head_box) and can_attack)
    or do_bboxes_collide(self,player) then
     self.spd_y=-2.0
     kill_player=true
    end
   end

   if kill_player then
    add_cr(function ()
     self.is_bullet_time=true
     player.is_bullet_time=true
     for i=0,3 do
      yield()
     end
     self.is_bullet_time=false
     player.is_bullet_time=false
     make_gore_explosion(v2(player.x,player.y))
     cls_smoke.init(v2(self.x,self.y),32,0)
     if player.input_port==self.input_port then
      -- killed a doppelgaenger
      -- scores[self.input_port+1]-=1
     else
      scores[self.input_port+1]+=1
     end
     player:kill()
    end)
   end
  end
 end

 for a in all(interactables) do
  if (do_bboxes_collide(self,a)) a:on_player_collision(self)
 end


-- if (not self.on_ground and frame%2==0) insert(self.ghosts,{x=self.x,y=self.y})
-- if ((self.on_ground or #self.ghosts>6)) popend(self.ghosts)
end

function cls_player:draw()
 if self.is_bullet_time then
  rectfill(self.x,self.y,self.x+8,self.y+8,10)
  return
 end
 if not self.is_teleporting then
  if (self.power_up_type==spr_power_up_invisibility and frame%60<50) return
  -- local dark=0
  -- for ghost in all(self.ghosts) do
  --  dark+=8
  --  darken(dark)
  --  spr(self.spr,ghost.x,ghost.y,1,1,self.flip.x,self.flip.y)
  -- end
  pal()

  pal(cols_face[1], cols_face[self.input_port + 1])
  pal(cols_hair[1], cols_hair[self.input_port + 1])
  if self.power_up!=nil then
   bspr(self.spr,self.x,self.y,self.flip.x,self.flip.y,powerup_colors[self.power_up_type])
  else
   spr(self.spr,self.x,self.y,1,1,self.flip.x,self.flip.y)
  end
  pal(cols_face[1], cols_face[1])
  pal(cols_hair[1], cols_hair[1])

  --[[
  local bbox=self:bbox()
  local bbox_col=8
  if self:is_solid_at(v2(0,0)) then
   bbox_col=9
  end
  bbox:draw(bbox_col)
  --bbox=self.feet_hitbox:to_bbox_at(self.pos)
  --bbox:draw(12)
  --bbox=self.head_hitbox:to_bbox_at(self.pos)
  --bbox:draw(12)
  print(self.spd:str(),64,64)
  --]]
 end
end
