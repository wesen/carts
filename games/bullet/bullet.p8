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
 return setmetatable(c,{__index=parent})
end

function bbox_bbox_clip(bbx,boundaries)
 return {
  aax=mid(boundaries.aax,bbx.aax,boundaries.bbx),
  aay=mid(boundaries.aay,bbx.aay,boundaries.bbx),
  bby=mid(boundaries.aax,bbx.bbx,boundaries.bbx),
  bby=mid(boundaries.aay,bbx.bby,boundaries.bby),
}
end

function bbox_pt_clip(x,y,bbox)
 return mid(bbox.aax,x,bbox.bbx),mid(bbox.aay,y,bbox.bby)
end

-- functions
function appr(val,target,amount)
 return (val>target and max(val-amount,target)) or min(val+amount,target)
end

function sign(v)
 return v>0 and 1 or v<0 and -1 or 0
end

function rndsign()
 return rnd(1)>0.5 and 1 or -1
end

function round(x)
 return flr(x+0.5)
end

function maybe(p)
 if (p==nil) p=0.5
 return rnd(1)<p
end

function mrnd(x)
 return rnd(x*2)-x
end

function rnd_elt(v)
 return v[min(#v,1+flr(rnd(#v)+0.5))]
end

function frame(interval,len)
 return flr(glb_frame/interval)%len
end

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

function v_idx(pos)
 return pos.x+pos.y*128
end

function angle2vec(angle)
 return cos(angle),sin(angle)
end

function shake(self,p)
 local a=rnd(1)
 self.shkx=cos(a)*p
 self.shky=sin(a)*p
end

function update_shake(self)
 if abs(self.shkx)+abs(self.shky)<1 then
  self.shkx=0
  self.shky=0
 end
 if glb_frame%4==0 then
  self.shkx*=-0.4-rnd(0.1)
  self.shky*=-0.4-rnd(0.1)
 end

end


cls_player=class(function(self)
 self.x=64
 self.y=64
 self.hp=10
 self.spd=2
 self.spr=1
end)

function cls_player:update()
 local xdir=0
 local ydir=0
 if (btn(0)) xdir-=1
 if (btn(1)) xdir+=1
 if (btn(2)) ydir-=1
 if (btn(3)) ydir+=1

 self.x+=xdir*self.spd
 self.y+=ydir*self.spd
end

function cls_player:draw()
 spr(self.spr,self.x+4,self.y+4)
end


--@include projectiles




glb_dt=0
glb_lasttime=time()
glb_frame=0

glb_mouse_x=0
glb_mouse_y=0

glb_prev_mouse_btn=0
glb_right_button=false

glb_p1=cls_player.init()

function _init()
 poke(0x5f2d, 1)
end

function _update60()
 local _time=time()
 glb_dt=_time-glb_lasttime
 glb_lasttime=_time

 glb_mouse_x=stat(32)
 glb_mouse_y=stat(33)
 local _mouse_btn=stat(34)
 glb_right_button=band(_mouse_btn,1)==1 and not band(glb_prev_mouse_btn,1)==0
 glb_right_button_dwn=band(_mouse_btn,1)==1
 glb_left_button=band(_mouse_btn,2)==1 and not band(glb_prev_mouse_btn,2)==0
 glb_prev_mouse_btn=_mouse_btn

 glb_p1:update()

 for _,p in pairs(glb_projectiles) do
  p:update()
 end
end

function _draw()
 cls(1)
 glb_frame+=1

 glb_p1:draw()

 for _,p in pairs(glb_projectiles) do
  p:draw()
 end
end


__gfx__
00000000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
