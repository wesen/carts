pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function f()
end

function _draw()
 cls()
 local a=1
 for i=0,10000 do
  f()
 end
 print(tostr(stat(1)),64,64,7)
end
