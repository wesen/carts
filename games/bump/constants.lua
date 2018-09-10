flg_solid=0
flg_ice=1

--first value is default
cols_face={ 7, 12 }
cols_hair={ 13, 10 }

p1_input=0
p2_input=1

btn_right=1
btn_up=2
btn_down=3
btn_left=0
btn_jump=4

-- physics tweaking
local maxrun=1
local maxfall=2
local gravity=0.12
local in_air_accel=0.1
local in_air_decel=0.05
local apex_speed=0.15
local fall_gravity_factor=2
local apex_gravity_factor=0.5
local wall_slide_maxfall=0.4
local ice_wall_maxfall=1
local jump_spd=1.2
local wall_jump_spd=maxrun+0.6
local spring_speed=3
local jump_button_grace_interval=5
local jump_max_hold_time=15
local ground_grace_interval=6
