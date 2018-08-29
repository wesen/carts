pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
foobar=0
foo2=0

test_cr=cocreate(function ()
 while true do
  foo2+=1
 end
end)

function _update()
 if foobar<=2 then
  printh("resume it")
  coresume(test_cr)
  printh("foo2 "..tostr(foo2))
 end
 foobar+=1
end

function _draw()
 cls()
 print(tostr(foobar),32,32)
 print(tostr(foo2),32,48)
end
