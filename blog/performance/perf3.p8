pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
x=0

function _draw()
 cls()
 local a=1
 for i=0,5000 do
  a=x
  a=x
  a=x
  a=x
  a=x
 end
 print(tostr(stat(1)),64,64,7)
end
