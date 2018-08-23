pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- todo
--[[
- collision detection
]]

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

local objs=class(function(self)
 self.objs={}
end)

function objs:add(obj)
 add(self.objs,obj)
end

function objs:del(obj)
 del(self.objs,obj)
 obj:destroy()
end

function objs:clear()
 for o in all(self.objs) do
  self:del(o)
 end
end

function objs:update()
 for obj in all(self.objs) do
  obj:update()
 end
end

function objs:draw()
 for obj in all(self.objs) do
  obj:draw()
 end
end

--

-- vectors
local v2mt={}
v2mt.__index=v2mt

function v2(x,y)
 local t={x=x,y=y}
 return setmetatable(t,v2mt)
end

function v2mt.__add(a,b)
 return v2(a.x+b.x,a.y+b.y)
end

function v2mt.__sub(a,b)
 return v2(a.x-b.x,a.y-b.y)
end

function v2mt.__mul(a,b)
 if (type(a)=="number") return v2(b.x*a,b.y*a)
 if (type(b)=="number") return v2(a.x*b,a.y*b)
 return v2(a.x*b.x,a.y*b.y)
end

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
end

local bboxvt={}
bboxvt.__index=bboxvt

function bbox(aa,bb)
 return setmetatable({aa=aa,bb=bb},bboxvt)
end

function bboxvt:w()
 return self.bb.x-self.aa.x
end

function bboxvt:h()
 return self.bb.y-self.aa.y
end

function bboxvt:is_inside(v)
 return v.x>=self.aa.x 
    and v.x<=self.bb.x  
    and v.y>=self.aa.y
    and v.y<=self.bb.y        
end

function bboxvt:collide(other)
 return other.bb.x > self.aa.x and
   other.bb.y > self.aa.y and
   other.aa.x < self.bb.x and
   other.aa.y < self.bb.y
end

function bboxvt:str()
 return self.aa:str().."-"..self.bb:str()
end

local hitboxvt={}
hitboxvt.__index=hitboxvt

function hitbox(offset,dim)
 return setmetatable({offset=offset,dim=dim},hitboxvt)
end

function hitboxvt:to_bbox_at(v)
 return bbox(self.offset+v,self.offset+v+self.dim)
end

function hitboxvt:str()
 return self.offset:str().."-("..self.dim:str()..")"
end
-->8
-- objects


typ_player=1
typ_obstacle=2

objects=objs.init()

class_object=class(function(self,typ,pos,hitbox)
 self.pos=pos
 self.hitbox=hitbox
 self.typ=typ
 self.has_collider=true
 objects:add(self)
end)

function class_object:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return self.hitbox:to_bbox_at(self.pos+offset)
end

function class_object:collide(typ,offset)
 local bb=self:bbox()
 for other in all(objects.objs) do
  if other~=nil and other.typ==typ and other!=self and other.has_collider and
    bb:collide(other:bbox()) then
    return other
  end
 end
end

function class_object:update()
end

function class_object:draw()
 local b=self:bbox()
 rect(b.aa.x,b.aa.y,b.bb.x,b.bb.y,7)
end

-->8
-- player

class_player=subclass(class_object,function(self)
 class_object._ctr(self,typ_player,v2(32,32),hitbox(v2(0,0),v2(8,8)))
end)

function class_player:update()
 if (btnp(0)) self.pos.x-=3
 if (btnp(1)) self.pos.x+=3
 if (btnp(2)) self.pos.y-=3
 if (btnp(3)) self.pos.y+=3
end

function class_player:draw()
 local res=player:collide(typ_obstacle,v2(0,0))
 local b=self:bbox()
 local col=8
 if (res~=nil) col=9
 rect(b.aa.x,b.aa.y,b.bb.x,b.bb.y,col)
end

player=class_player.init()
class_object.init(typ_obstacle,v2(10,10),hitbox(v2(0,0),v2(8,8)))

function _update60()
 objects:update()
end

function _draw()
 cls()
 objects:draw()
end
