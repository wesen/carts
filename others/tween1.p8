pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function linear(t, b, c, d)
 return c*t/d+b
end

local distance=50
local duration=1

function downfunc(v)
 return linear(v,0,distance,duration)
end

function upfunc(v)
 return linear(v,distance,-distance,duration)
end

local easeprop=0
local timeelapsed=0
local currentfunc=downfunc
local lasttime=time()
local dt=0

function _update()
 t=time()
 dt=t-lasttime
 lasttime=t
 timeelapsed+=dt
 
 if timeelapsed>duration then
  timeelapsed=0
  if currentfunc==downfunc then
   currentfunc=upfunc
  else
   currentfunc=downfunc
  end
 end
 
 easeprop=currentfunc(timeelapsed)
end

function _draw()
 rectfill(0,0,128,128,3)
 circfill(64,40+easeprop,20,15)
end

