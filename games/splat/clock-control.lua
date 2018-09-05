local slow_time_factor=0.2
local slow_time_countdown=3

local state_normal_time=0
local state_slow_time=1

cls_clock_control=class(function(self)
 self.time_factor=1
 self.lasttime=time()
 self.countdown=0
 self.state=state_normal_time
end)

function cls_clock_control:get_dt()
 local dt=time()-lasttime
 self.countdown-=dt
 lasttime=time()
 if (self.state==state_slow_time) return dt*slow_time_factor
 return dt
end

function cls_clock_control:update()
 if self.state==state_slow_time and self.countdown<0 then
  self.state=state_normal_time
 end
end

function cls_clock_control:on_enemy_winds_up()
 self.state=state_slow_time
 self.countdown=slow_time_countdown
end

function cls_clock_control:on_enemy_attacks()
 self.state=state_normal_time
end

function cls_clock_control:on_player_attacks()
 self.state=state_slow_time
 self.countdown=slow_time_countdown
end
