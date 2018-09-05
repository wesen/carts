local countdown_idle=2
local countdown_winding_up=1
local countdown_attacking=1

local hit_interval=6

local state_idle=0
local state_winding_up=1
local state_attacking=2
local state_stunned=3
local enemy_colors={}
enemy_colors[state_idle]=7
enemy_colors[state_winding_up]=9
enemy_colors[state_attacking]=8
enemy_colors[state_stunned]=7

cls_enemy_manager=class(function(self)
 self.enemies={}
 self.hit_countdown=2
end)

function cls_enemy_manager:draw()
 foreach(self.enemies,function(e)
  rectfill(e.pos.x,e.pos.y,e.pos.x+8,e.pos.y+8,enemy_colors[e.state])
 end)
end

function cls_enemy_manager:update()
 self.hit_countdown-=dt

 local lowest_countdown=countdown_idle
 local next_enemy=nil

 foreach(self.enemies,function(e)
  e.countdown-=dt
  if e.state==state_idle and e.countdown<lowest_countdown then
   next_enemy=e
   lowest_countdown=e.countdown
  elseif e.state==state_winding_up and e.countdown<0 then
   printh("ATTACK")
   e.state=state_attacking
   e.countdown=countdown_attacking
  elseif e.state==state_attacking and e.countdown<0 then
   e.state=state_idle
   e.countdown=countdown_idle
  end
 end)

 if self.hit_countdown<0 and next_enemy!=nil then
  self.hit_countdown=hit_interval
  next_enemy.state=state_winding_up
  next_enemy.countdown=countdown_winding_up
 end
end

function cls_enemy_manager:add_enemy(pos)
 add(self.enemies,{
  state=state_idle,
  pos=pos,
  countdown=0
})
end
