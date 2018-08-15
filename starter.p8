pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--helpers

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

--
local objs=class(function(self,name)
 self.name=name
 self.objs={}
end)

function objs:add(obj)
 add(self.objs,obj)
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

-- coroutines
crs={}

function tick_crs()
 for cr in all(crs) do
  if costatus(cr)!='dead' then
   coresume(cr)
  else
   printh("done")
   del(crs, cr)
  end
 end
end

function add_cr(f)
 add(crs,cocreate(f))
end

-- tweens
--- function for calculating 
-- exponents to a higher degree
-- of accuracy than using the
-- ^ operator.
-- function created by samhocevar.
-- source: https://www.lexaloffle.com/bbs/?tid=27864
-- @param x number to apply exponent to.
-- @param a exponent to apply.
-- @return the result of the 
-- calculation.
function pow(x,a)
  if (a==0) return 1
  if (a<0) x,a=1/x,-a
  local ret,a0,xn=1,flr(a),x
  a-=a0
  while a0>=1 do
      if (a0%2>=1) ret*=xn
      xn,a0=xn*xn,shr(a0,1)
  end
  while a>0 do
      while a<1 do x,a=sqrt(x),a+a end
      ret,a=ret*x,a-1
  end
  return ret
end

function inoutquint(t, b, c, d)
  t = t / d * 2
  if (t < 1) return c / 2 * pow(t, 5) + b
  return c / 2 * (pow(t - 2, 5) + 2) + b
end

function inexpo(t, b, c, d)
  if (t == 0) return b
  return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end

function outexpo(t, b, c, d)
  if (t == d) return b + c
  return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end

function inoutexpo(t, b, c, d)
  if (t == 0) return b
  if (t == d) return b + c
  t = t / d * 2
  if (t < 1) return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
  return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end

function move_to(obj,x,y,d,easetype)
 local timeelapsed=0
 local lasttime=0
 local bx=obj.x
 local cx=x-bx
 local by=obj.y
 local cy=y-by
 add_cr(function()
  while timeelapsed<d do
   t=time()
   local dt=t-lasttime
   lasttime=t
   timeelapsed+=dt
   if (timeelapsed>d) return
   obj.x=easetype(timeelapsed,bx,cx,d)
   obj.y=easetype(timeelapsed,by,cy,d)
   yield() 
  end
 end)
end
-->8
-- main functions

circles=objs.init("circles")

function _init()
 local c=circle.init(64,64,3)
 circles:add(c)
 move_to(c,c.x+20,c.y+20,2,inoutexpo)
end

function _update() 
 tick_crs()
end

function _draw()
 cls()
 circles:draw()
end
-->8
-- classes
circle=class(function(self,x,y,r)
 self.x=x
 self.y=y
 self.r=r
end)

function circle:draw()
 circfill(self.x,self.y,self.r)
end
