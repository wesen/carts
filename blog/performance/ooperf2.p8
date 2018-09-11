pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-->8
function class (init)
  local c = {}
  c.__index = c
  c._ctr=init
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    self.destroyed=false
    return self
  end
  c.destroy=function(self)
   self.destroyed=true
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,parent)
end

-->8
function _init()
end

cls_foobar=class(function(self)
 self.x=23
 self.y=23
end)

function cls_foobar:foo()
 self.x+=self.x
end

function foo(a)
 a.x+=a.x
end

function _draw()
 cls()

 a={x=23,y=23} 
 
 for i=0,10000 do
  foo(a)
 end
 
 print(tostr(stat(1)),64,64,7)
end
