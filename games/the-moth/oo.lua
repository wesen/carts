function class (typ,init)
  local c = {}
  c.__index = c
  c._ctr=init
  c.typ=typ
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    self.typ=typ
    self.destroyed=false
    return self
  end
  c.destroy=function(self)
   self.destroyed=true
  end
  return c
end

function subclass(typ,parent,init)
 local c=class(typ,init)
 return setmetatable(c,{__index=parent})
end

