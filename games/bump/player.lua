players={}
connected_players={}
combo_kills={0,0,0,0}
combo_kill_timer={0,0,0,0}
player_cnt=0

start_sprites={1,130,146,226}

function check_for_new_players()
 for i=0,3 do
  if (btnp(btn_jump,i) or btnp(btn_action,i)) and connected_players[i]==nil then
   room:spawn_player(i)
  end
 end
end

cls_player=subclass(cls_actor,function(self,pos,input_port)
 self.hitbox={x=2,y=0.5,dimx=4,dimy=7.5}
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
 self.start_spr=start_sprites[self.input_port+1]
 self.spr=self.start_spr

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0

 self.is_teleporting=false
 self.on_ground=false
 self.is_bullet_time=false
 self.is_dead=false
end)

function cls_player:update_bbox()
 if self.power_up_type!=spr_pwrup_shrink and not (solid or actor) then
  cls_actor.update_bbox(self)
  self.head_box={
    aax=self.x+0,
    aay=self.y-1
   }
  self.head_box.bbx=self.head_box.aax+8
  self.head_box.bby=self.head_box.aay+1

  self.feet_box={
    aax=self.x+2,
    aay=self.y+7
   }
  self.feet_box.bbx=self.feet_box.aax+4
  self.feet_box.bby=self.feet_box.aay+1

  -- we should actually never collide at the start of the frame
  -- if we are, use the small hitbox
  local solid=solid_at_offset(self,0,0)
  local actor,a=self:is_actor_at(0,0)
  if actor or solid then
   self:update_shrunk_bbox()
  end
 else
  self:update_shrunk_bbox()
 end
end

function cls_player:update_shrunk_bbox()
 self.aax=self.x+3
 self.aay=self.y+4.5
 self.bbx=self.aax+3
 self.bby=self.aay+3.5

 self.head_box={
   aax=self.x+2,
   aay=self.y+5
  }
 self.head_box.bbx=self.head_box.aax+4
 self.head_box.bby=self.head_box.aay+1

 self.feet_box={
   aax=self.x+2,
   aay=self.y+7
  }
 self.feet_box.bbx=self.feet_box.aax+4
 self.feet_box.bby=self.feet_box.aay+1
end

function cls_player:smoke(spr,dir)
 return cls_smoke.init(v2(self.x,self.y),spr,dir)
end

function cls_player:kill()
 if not self.is_dead then
  del(players,self)
  del(actors,self)
  self.is_dead=true
  add_shake(3)
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
end

function cls_player:update()
 if is_outside_room(self) then
  self:kill()
  sfx(1)
 elseif self.is_teleporting or self.is_bullet_time then
 else
  self:update_normal()
 end
end

function cls_player:update_normal()
 local nr=self.input_port+1

 if combo_kill_timer[nr]>0 then
  combo_kill_timer[nr]-=dt
 else
  combo_kills[nr]=0
 end

 -- power up countdown
 if self.power_up_countdown!=nil then
  self.power_up_countdown-=dt
  if self.power_up_countdown<0 then
   self:clear_power_up()
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

 if self.power_up_type==spr_pwrup_superspeed then
  maxrun*=1.5
  decel*=2
  accel*=2
 elseif self.power_up_type==spr_pwrup_superjump then
  jump_spd*=1.5
 elseif self.power_up_type==spr_pwrup_gravitytweak then
  gravity*=0.7
  maxfall*=0.5
 end

 self.on_ground=solid_at_offset(self,0,1)
 local on_ice=ice_at_offset(self,0,1)

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
 if input!=0 and solid_at_offset(self,input,0)
    and not self.on_ground and self.spd_y>0 then
  is_wall_sliding=true
  maxfall=wall_slide_maxfall
  if (ice_at_offset(self,input,0)) maxfall=ice_wall_maxfall
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
   local wall_dir=solid_at_offset(self,-3,0) and -1
        or solid_at_offset(self,3,0) and 1
        or 0
   if wall_dir!=0 then
    self.jump_interval=0
    self.spd_y=-1
    sfx(0)
    self.spd_x=-wall_dir*wall_jump_spd
    self:smoke(spr_wall_smoke,-wall_dir*.3)
    self.jump_button.hold_time+=1
   end
  end
 end

 if (not self.on_ground) self.spd_y=appr(self.spd_y,maxfall,gravity)

 self:move_x(self.spd_x)
 self:move_y(self.spd_y)

 -- avoid ceiling sliding
 if self.spd_y==0 then
  self.jump_button.hold_time=0
 end

 -- animation
 if input==0 then
  self.spr=self.start_spr
 elseif is_wall_sliding then
  self.spr=self.start_spr+3
 elseif not self.on_ground then
  self.spr=self.start_spr+2
 else
  self.spr=self.start_spr+flr(frame/4)%3
 end

 if (self.power_up_type==spr_pwrup_shrink) self.spr+=4

 -- interact with players
 for player in all(players) do
  if self!=player and player.power_up_type!=spr_pwrup_invincibility then
   local kill_player=false

   if self.power_up_type==spr_pwrup_invincibility
    and do_bboxes_collide_offset(self,player,input,0) then
    kill_player=true
   else
    -- attack
    local can_attack=not self.on_ground

    if (do_bboxes_collide(self.feet_box,player.head_box) and can_attack)
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
      self:add_score(0)
     else
      self:add_score(1)
     end
     player:kill()
     sfx(1)
    end)
   end
  end
 end

 local solid=solid_at_offset(self,0,0)
 local actor,a=self:is_actor_at(0,0)
 if actor or solid then
  -- we're still solid, even though we shouldn't
  -- to avoid having the player stuck, we're just gonna kill him
  printh("kill because actor "..tostr(actor).." solid "..tostr(solid))
  self:kill()
  sfx(1)
 end

 for a in all(interactables) do
  if (do_bboxes_collide(self,a)) a:on_player_collision(self)
 end

 if (not self.on_ground and frame%2==0) insert(self.ghosts,{x=self.x,y=self.y})
 if ((self.on_ground or #self.ghosts>6)) popend(self.ghosts)
end

function cls_player:add_score(add)
 local nr=self.input_port+1
 scores[nr]+=add
 if add>=0 then
  combo_kill_timer[nr]=3
  combo_kills[nr]+=1
  if combo_kills[nr]==1 then
   cls_score_particle.init(v2(self.x,self.y),"kill",1,7)
  elseif combo_kills[nr]==2 then
   cls_score_particle.init(v2(self.x,self.y),"double kill",10,1)
  elseif combo_kills[nr]==3 then
   cls_score_particle.init(v2(self.x,self.y),"triple kill",9,1)
  elseif combo_kills[nr]==4 then
   cls_score_particle.init(v2(self.x,self.y),"killing spree",8,7)
   combo_kill_timer[nr]=0
   combo_kills[nr]=0
  end
 end

 if mode==mode_game and scores[nr]>win_threshold then
  winning_player=nr
  end_game()
 end
end

function cls_player:clear_power_up()
 if self.power_up!=nil then
  self.power_up:on_powerup_stop(self)
  self.power_up=nil
  self.power_up_type=nil
  self.power_up_countdown=nil
 end
end

function cls_player:draw()
 if self.is_bullet_time then
  rectfill(0,0,128,128,7)
  return
 end
 if not self.is_teleporting then
  if (self.power_up_type==spr_pwrup_invisibility and frame%60<50) return
  local dark=0
  for ghost in all(self.ghosts) do
   dark+=12
   darken(dark)
   spr(self.spr,ghost.x,ghost.y,1,1,self.flip.x,self.flip.y)
  end
  pal()

  spr(self.spr,self.x,self.y,1,1,self.flip.x,self.flip.y)

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
