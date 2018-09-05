local frame=0
local dt=0
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
