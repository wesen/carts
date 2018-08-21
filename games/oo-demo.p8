pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function class (init)
  local c = {}
  c.__index = c
  c._ctr=init
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    return self
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,parent)
end

someclass=class(function (self, name)
  self.name=name
end)

function someclass:foobar()
 print("foobar "..tostr(self.name))
end

otherclass=subclass(someclass,
function (self, blop)
  someclass._ctr(self,"foobar")
  self.blop=blop
end)

function otherclass:testtest()
 print("otherclass "..tostr(self.blop))
end

function otherclass:foobar()
 print("other foobar"..tostr(self.blop))
 someclass.foobar(self)
end

o1=someclass.init("hello")
o2=otherclass.init(23)

o1:foobar()
o2:foobar()
o2:testtest()

