pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- this is possible in standard lua (try it here: [http://www.lua.org/cgi-bin/demo](http://www.lua.org/cgi-bin/demo))

-- class helper (include this once, use it for all your classes)
function class (init)
  local c = {}
  c.__index = c
  function c.init (...)
    local self = setmetatable({},c)
    init(self,...)
    return self
  end
  return c
end
-- end class helper

-- actual class definition
local someclass = class(function (self, name)
  self.name = name
end)

function someclass:setname (name)
  self.name = name
end
-- end class definition

local otherclass = class(function (self, name)
  self.name=name

local someclassinstance = someclass.init("monkey")
print(someclassinstance.name) -- "monkey"
someclassinstance:setname("banana")
print(someclassinstance.name) -- "banana"
