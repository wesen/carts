local frame=0
local dt=0
local time_factor=1
local lasttime=time()
local room=nil

local actors={}
local tiles={}
local crs={}
local draw_crs={}

local player=nil
local enemy_manager=nil

local is_fading=false
local is_screen_dark=false

local dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,13}
