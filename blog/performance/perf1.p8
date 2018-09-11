pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _draw()
 cls()
 local x=1
 for i=0,10000 do
  x*=1
  x*=1
  x*=1
  x*=1
  x*=1
 end
 print(tostr(stat(1)),64,64,7)
end
