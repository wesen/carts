players={}

player_cnt=0

cls_player=subclass(typ_player,cls_actor,function(self,pos,input_port)
 cls_actor._ctr(self,pos)
 -- players are handled separately
 del(actors,self)
 add(players,self)

 self.ghosts={}

 self.nr=player_cnt
 player_cnt+=1

 self.flip=v2(false,false)
 self.input_port=input_port
 self.jump_button=cls_button.init(btn_jump, input_port)
 self.spr=1
 self.hitbox=hitbox(v2(2,0.5),v2(4,7.5))
 self.head_hitbox=hitbox(v2(0,-1),v2(8,1))
 self.feet_hitbox=hitbox(v2(2,7),v2(4,1))

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0

 self.is_teleporting=false
 self.on_ground=false
end)

function cls_player:smoke(spr,dir)
 return cls_smoke.init(self.pos,spr,dir)
end

function cls_player:kill()
 del(players,self)
  sfx(1)
 room:spawn_player(self.input_port)
end

function cls_player:update()
 if self.is_teleporting then
 else
  self:update_normal()
 end
end

function cls_player:update_normal()
 -- from celeste's player class
 local input=btn(btn_right, self.input_port) and 1
    or (btn(btn_left, self.input_port) and -1
    or 0)

 self.jump_button:update()

 local maxrun=1
 local accel=0.3
 local decel=0.2

 local ground_bbox=self:bbox(vec_down)
 self.on_ground,tile=solid_at(ground_bbox)
 local on_actor=self:is_actor_at(v2(input,0))
 local on_ice=ice_at(ground_bbox)

 if self.on_ground then
  self.on_ground_interval=ground_grace_interval
 elseif self.on_ground_interval>0 then
  self.on_ground_interval-=1
 end
 local on_ground_recently=self.on_ground_interval>0
 local on_gore=false

 if not self.on_ground then
  accel=0.1
  decel=0.05
 else
  if tile!=nil then
   accel,decel=room:get_friction(tile,dir_down)
   on_gore=room:get_gore(tile,dir_down)>0
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
  if input==0 and abs(self.spd.x)>0.3
     and (maybe(0.15) or self.prev_input!=0) then
   if on_gore then
    local s=self:smoke(spr_slide_smoke,-input)
    s.is_gore=true
   elseif on_ice then
    self:smoke(spr_slide_smoke,-input)
   end
  end
 end
 self.prev_input=input

 -- x movement
 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel)
 else
  self.spd.x=appr(self.spd.x,0,decel)
 end
 if (self.spd.x!=0) self.flip.x=self.spd.x<0

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
    and not self.on_ground and self.spd.y>0 then
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
    sfx(0)
   end
   self.on_ground_interval=0
   self.spd.y=-1.2
   self.jump_button.hold_time+=1
  elseif self.jump_button:was_just_pressed() then
   -- check for wall jump
   local wall_dir=self:is_solid_at(v2(-3,0)) and -1
        or self:is_solid_at(v2(3,0)) and 1
        or 0
   if wall_dir!=0 then
    self.jump_interval=0
    self.spd.y=-1
    self.spd.x=-wall_dir*(maxrun+.6)
    self:smoke(spr_wall_smoke,-wall_dir*.3)
    self.jump_button.hold_time+=1
   end
  end
 end

 if (not self.on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

 self:move(self.spd)

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
 local feet_box=self.feet_hitbox:to_bbox_at(self.pos)
 for player in all(players) do
  if self!=player then

   -- attack
   local head_box=player.head_hitbox:to_bbox_at(player.pos)
   local can_attack=not self.on_ground and self.spd.y>0
   -- printh(tostr(self.nr).." attack on ground "..tostr(on_ground))

   if (feet_box:collide(head_box) and can_attack) or self:bbox():collide(player:bbox()) then
    make_gore_explosion(player.pos)
    cls_smoke.init(self.pos,32,0)
    self.spd.y=-2.0
    player:kill()
    scores[self.input_port+1]+=1
   end
  end
 end

 if (not self.on_ground and frame%2==0) insert(self.ghosts,self.pos:clone())
 if ((self.on_ground or #self.ghosts>4)) popend(self.ghosts)
end

function cls_player:draw()
 if not self.is_teleporting then
  local dark=0
  for ghost in all(self.ghosts) do
   dark+=10
   darken(dark)
   spr(self.spr,ghost.x,ghost.y,1,1,self.flip.x,self.flip.y)
  end
  pal()

  pal(cols_face[1], cols_face[self.input_port + 1])
  pal(cols_hair[1], cols_hair[self.input_port + 1])

  spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)

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
