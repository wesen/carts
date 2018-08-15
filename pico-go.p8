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
   del(crs, cr)
  end
 end
end

function add_cr(f)
 local cr=cocreate(f)
 add(crs,cr)
 return cr
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

function wait_for(d,cb)
 local end_time=time()+d
 local cr=add_cr(function()
  while time()<end_time do
   yield()
  end
  if (cb!=nil) cb()
 end)
 while costatus(cr)!='dead' do
  yield()
 end
end

function animate(obj,sprs,d,cb)
 add_cr(function()
  for s in all(sprs) do
   obj.spr=s
   wait_for(d)
  end
  cb()
 end)
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
-- classes
function v_idx(x,y) 
 return y*16+x
end

function idx_v(v)
 return {v%16,flr(v/16)}
end

class_node=class(function(self,x,y)
 self.x=x
 self.y=y
 self.spr=1
 self.is_goal=false
 self.initialized=false
end)

function class_node:initialize()
 local sprs={16,17,18,19}
 if (self.is_goal) sprs[4]=20
 animate(self,sprs,0.1,function()
  self.initialized=true
 end)
end

class_link=class(function(self)
 self.initialized=false
end)

class_board=class(function(self)
 self.nodes={}
 self.enemies={}
 self.hlinks={}
 self.vlinks={}
 for x=0,15 do
  for y=0,15 do
   local m=mget(x,y)
   local f=fget(m)
   local v=v_idx(x,y)
   if band(f,1)==1 then
    -- node
    local n=class_node.init(x,y)
    self.nodes[v]=n
    n:initialize()
    if band(f,2)==2 then
     self.goal=n
     n.is_goal=true
    end
   elseif m==2 then
    self.hlinks[v]=true
   elseif m==3 then
    self.vlinks[v]=true
   end
  end
 end
end)

function class_board:draw()
 for v,n in pairs(self.nodes) do
  spr(n.spr,n.x*8,n.y*8)
 end
 for v,n in pairs(self.hlinks) do
  local pos=idx_v(v)
  spr(2,pos[1]*8,pos[2]*8)
 end
 for v,n in pairs(self.vlinks) do
  local pos=idx_v(v)
  spr(3,pos[1]*8,pos[2]*8)
 end
end

-->8
-- main functions

board=class_board.init()

function _init()
end

function _update() 
 tick_crs()
end

function _draw()
 cls()
 board:draw()
end
-->8
-- todo

--[[
x helper methods
x board graph
x draw graph
- draw graph animations
- player movement
- sprites
- player arrows
- goal node
- win condition
- start screen
- end screen
- enemies
]]
__gfx__
00000000606060600000000000060000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700600000000000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000060000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000600000006666666600060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000060000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600000000000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060606060000000000060000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000000600000060000000066000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000000060000066000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000003000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010201020102010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000003000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010201020102040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000