pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
glb_debug=true
glb_timescale=1

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

function v2mt.__div(a,b)
 if (type(a)=="number") return v2(b.x/a,b.y/a)
 if (type(b)=="number") return v2(a.x/b,a.y/b)
 return v2(a.x/b.x,a.y/b.y)
end

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:min(v)
 return v2(min(self.x,v.x),min(self.y,v.y))
end

function v2mt:max(v)
 return v2(max(self.x,v.x),max(self.y,v.y))
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:sqrmagnitude()
 return self.x^2+self.y^2
end

function v2mt:normalize()
 return self/self:magnitude()
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
end

function v2mt:flr()
 return v2(flr(self.x),flr(self.y))
end

function v2mt:clone()
 return v2(self.x,self.y)
end

dir_down=0
dir_right=1
dir_up=2
dir_left=3

vec_down=v2(0,1)
vec_up=v2(0,-1)
vec_right=v2(1,0)
vec_left=v2(-1,0)

function dir2vec(dir)
 local dirs={v2(0,1),v2(1,0),v2(0,-1),v2(-1,0)}
 return dirs[(dir+4)%4]
end

function angle2vec(angle)
 return v2(cos(angle),sin(angle))
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

function bboxvt:str()
 return self.aa:str().."-"..self.bb:str()
end

function bboxvt:draw(col)
 rect(self.aa.x,self.aa.y,self.bb.x-1,self.bb.y-1,col)
end

function bboxvt:to_tile_bbox()
 local x0=max(0,flr(self.aa.x/8))
 local x1=min(room.dim.x,(self.bb.x-1)/8)
 local y0=max(0,flr(self.aa.y/8))
 local y1=min(room.dim.y,(self.bb.y-1)/8)
 return bbox(v2(x0,y0),v2(x1,y1))
end

function bboxvt:collide(other)
 return other.bb.x > self.aa.x and
   other.bb.y > self.aa.y and
   other.aa.x < self.bb.x and
   other.aa.y < self.bb.y
end

function bboxvt:clip(p)
 return v2(mid(self.aa.x,p.x,self.bb.x),
           mid(self.aa.y,p.y,self.bb.y))
end

function bboxvt:shrink(amt)
 local v=v2(amt,amt)
 return bbox(v+self.aa,self.bb-v)
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

glb_draw_crs={}
glb_crs={}

function tick_crs(crs_)
 for cr in all(crs_) do
  if costatus(cr)!='dead' then
   local status,err=coresume(cr)
   if (not status) printh("cr error "..err)
  else
   del(crs_,cr)
  end
 end
end

function add_cr(f,crs_)
 local cr=cocreate(f)
 add(crs_,cr)
 return cr
end

function wait_for(t)
 while t>0 do
  t-=dt
  yield()
 end
end

dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,13}

function darken(p,_pal)
 for j=1,15 do
  local kmax=(p+(j*1.46))/22
  local col=j
  for k=1,kmax do
   if (col==0) break
   col=dpal[col]
  end
  if (col==14) col=13
  if (col==2) col=5
  if (col==8) col=5
  pal(j,col,_pal)
 end
end

function palbg(col)
 for i=1,16 do
  pal(i,col)
 end
end

function bspr(s,x,y,flipx,flipy,col)
 palbg(col)
 spr(s,x-1,y,1,1,flipx,flipy)
 spr(s,x+1,y,1,1,flipx,flipy)
 spr(s,x,y-1,1,1,flipx,flipy)
 spr(s,x,y+1,1,1,flipx,flipy)
 pal()
 spr(s,x,y,1,1,flipx,flipy)
end

function bstr(s,x,y,c1,c2)
	for i=0,2 do
	 for j=0,2 do
	  if not(i==1 and j==1) then
	   print(s,x+i,y+j,c1)
	  end
	 end
	end
	print(s,x+1,y+1,c2)
end

function draw_rounded_rect1(x,y,w,h,col_bg,col_border)
 col_border=col_border or col_bg
 local x2=x+w
 local y2=y+h
 line(x,y-1,x2-1,y-1,col_border)
 line(x,y2,x2-1,y2,col_border)
 line(x-1,y,x-1,y2-1,col_border)
 line(x2,y,x2,y2-1,col_border)
 rectfill(x,y,x2-1,y2-1,col_bg)
end

function draw_rounded_rect2(x,y,w,h,col_bg,col_border1,col_border2)
 col_border1=col_border1 or col_bg
 col_border2=col_border2 or col_border1

 local y2=y+h
 local x2=x+w

 line(x,y-2,x2-1,y-2,col_border2)
 line(x,y+h+1,x2-1,y+h+1,col_border2)
 line(x-2,y,x-2,y2-1,col_border2)
 line(x2+1,y,x2+1,y2-1,col_border2)
 line(x,y-1,x2-1,y-1,col_border1)
 line(x,y2,x2-1,y2,col_border1)
 line(x-1,y,x-1,y2-1,col_border1)
 line(x2,y,x2,y2-1,col_border1)
 pset(x-1,y-1,col_border2)
 pset(x2,y-1,col_border2)
 pset(x-1,y2,col_border2)
 pset(x2,y2,col_border2)
 rectfill(x,y,x2-1,y2-1,col_bg)
 pset(x,y,col_border1)
 pset(x,y2-1,col_border1)
 pset(x2-1,y2-1,col_border1)
 pset(x2-1,y,col_border1)
end

glb_particles={}
glb_pwrup_particles={}

cls_particle=class(function(self,pos,lifetime,sprs)
 self.x=pos.x+mrnd(1)
 self.y=pos.y
 add(glb_particles,self)
 self.flip_h=false
 self.flip_v=false
 self.t=0
 self.lifetime=lifetime
 self.sprs=sprs
 self.weight=0
end)

function cls_particle:random_flip()
 self.flip_h=maybe()
 self.flip_v=maybe()
end

function cls_particle:random_angle(spd)
 local angle=rnd(1)
 self.spd_x=cos(angle)*spd
 self.spd_y=sin(angle)*spd
end

function cls_particle:update()
 self.aax=self.x+2
 self.bbx=self.x+4
 self.aay=self.y+2
 self.bby=self.y+4
 self.t+=glb_dt

 if self.t>self.lifetime then
   del(glb_particles,self)
   return
 end

 self.x+=self.spd_x
 self.aax+=self.spd_x
 self.bbx+=self.spd_x
 self.y+=self.spd_y
 self.aay+=self.spd_y
 self.bby+=self.spd_y
 self.spd_y=appr(self.spd_y,2,0.12)
end

function cls_particle:draw()
 local idx=flr(#self.sprs*(self.t/self.lifetime))
 local spr_=self.sprs[1+idx]
 spr(spr_,self.x,self.y,1,1)
end

cls_score_particle=class(function(self,x,y,val,c2,c1)
 self.x=x
 self.y=y
 self.spd_x=mrnd(0.2)
 self.spd_y=-rnd(0.2)-0.4
 self.c2=c2
 self.c1=c1
 self.val=val
 self.t=0
 self.lifetime=1
 add(glb_particles,self)
end)

function cls_score_particle:update()
 self.t+=glb_dt
 self.x+=self.spd_x+rnd(.1)
 self.x=mid(rnd(5),self.x,128-rnd(5)-4*#self.val)
 self.y+=self.spd_y
 if (self.t>self.lifetime) del(glb_particles,self)
end

function cls_score_particle:draw()
 bstr(self.val,self.x,self.y,self.c1,self.c2)
end

function make_score_particle_explosion(s,n,x,y,c2,c1,spread_x,spread_y)
 spread_x=spread_x or 10
 spread_y=spread_y or 8
 for i=1,n do
  local p=cls_score_particle.init(x+mrnd(spread_x),y+mrnd(spread_y),s,c2,c1)
  p.spd_y*=1
  p.lifetime=2
 end
end

function make_mouse_text_particle(text,c2,c1)
 cls_score_particle.init(mid(glb_mouse_x+5-(#text/2)*4,5,80),glb_mouse_y+2,
  text,0,7)
end

cls_pwrup_particle=class(function(self,x,y,a,cols)
 self.spd_x=cos(a)*.8
 self.cols=cols
 self.spd_y=sin(a)*.8
 self.x=x+self.spd_x*5
 self.y=y+self.spd_y*5
 self.t=0
 self.lifetime=0.8
 add(glb_pwrup_particles,self)
end)

function cls_pwrup_particle:update()
 self.t+=glb_dt
 self.y+=self.spd_y
 self.x+=self.spd_x
 self.spd_y*=0.81
 self.spd_x*=0.81
 if (self.t>self.lifetime) del(glb_pwrup_particles,self)
end

function cls_pwrup_particle:draw()
 local col=self.cols[flr(#self.cols*self.t/self.lifetime)+1]
 circfill(self.x,self.y,(2-self.t/self.lifetime*2),col)
end

pwrup_colors={
 {8,2,1},
 {7,6,5},
 {9,8,7,2},
 {6,6,5,1},
 {12,13,2,1},
 {9,8,2,1},
 {11,3,6,1}
}
function make_pwrup_explosion(x,y,explode)
 local radius=20
 local off=mrnd(1)
 local cols=rnd_elt(pwrup_colors)
 local spd_mod=4+mrnd(0.5)
 local inc=0.12+mrnd(0.03)

 for i=0,1,inc do
  local p=cls_pwrup_particle.init(x,y,i+off,cols)
  p.spd_x*=spd_mod
  p.spd_y*=spd_mod
 end

 if explode then
  local radius=14
  add_cr(function ()
   for i=0,1 do
    local r=outexpo(i,radius,-radius,20)
    circfill(x,y,r,cols[1])
    yield()
   end
  end, glb_draw_crs)
 end
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

function cr_move_to(obj,target_x,target_y,d,easetype)
 local t=0
 local bx=obj.x
 local cx=target_x-obj.x
 local by=obj.y
 local cy=target_y-obj.y
 while t<d do
  t+=dt
  if (t>d) return
  obj.x=round(easetype(t,bx,cx,d))
  obj.y=round(easetype(t,by,cy,d))
  yield()
 end
end

cls_button=class(function(self,x,y,text)
 self.x=x
 self.y=y
 self.text=text
 self.w=(#self.text)*4+1
 self.h=5
 self.is_visible=function() return false end
 self.is_active=function() return false end
 self.on_click=function() end
 self.on_hover=function() end
 self.should_blink=function() return false end
end)

function cls_button:is_mouse_over()
  local x=self.x
  local y=self.y
  return glb_mouse_x>=x
    and glb_mouse_x<=x+self.w
    and glb_mouse_y>=y-1
    and glb_mouse_y<=y+self.h+1
end

function cls_button:draw()
 local x=self.x
 local y=self.y
 local w=self.w
 local h=self.h
 local bg=self.is_active() and glb_bg_col2 or 13
 local fg=self.is_active() and 7 or 6

 if self:is_visible() then
  if self:should_blink() then
   if frame(12,2)==0 then
    draw_rounded_rect2(x-1,y-1,w+2,h+2,bg,bg,fg)
   else
    draw_rounded_rect2(x,y,w,h,bg,bg,fg)
   end
  else
   draw_rounded_rect2(x,y,w,h,bg,bg,fg)
  end

  if self:is_mouse_over() then
   self.on_hover()
   if glb_mouse_left_down then
    self.on_click()
   end
  end
  print(self.text,x+1,y,fg)
 end
end

cls_dialogbox=class(function(self)
 self.visible=true
 self.text={}
 self.shkx=0
 self.shky=0
 self.prev_visible=false
 self.buildup=0
end)

glb_dialogbox=cls_dialogbox.init()

function cls_dialogbox:shake(p)
 shake(self,p)
end


function cls_dialogbox:draw()
 update_shake(self)


 if not self.visible then
  self.prev_visible=self.visible
  return
 end

 local y=62
 local x=15+self.shkx
 if (glb_mouse_y>56) y=8
 local h=14+(#self.text-1)*8
 local w=98

 if not self.prev_visible then
  self.buildup=0
 end

 local n=7
 if self.buildup<n then
  self.buildup+=1
  local actual_h=inexpo(self.buildup,0,h+20,n)
  local actual_w=inexpo(self.buildup,0,120,n)
  y+=h/2-actual_h/2
  x+=w/2-actual_w/2

  draw_rounded_rect2(x,y+0,actual_w,actual_h,12,1,6)
  if (self.buildup==n) self:shake(5)
 else
  y+=self.shky

  draw_rounded_rect2(x,y+0,w,h,12,1,6)
  if #self.text>=1 then
   local txt=self.text[1][2]
   bstr(txt,64-#txt*2+self.shkx,y+3,1,7)
  end
  for i=2,#self.text do
   print(self.text[i][2],x+7,y+i*8-2,self.text[i][1])
  end
 end

 self.prev_visible=self.visible
end

cls_mouse=class(function(self)
 self.trails={}
 self.idx=1
 self.prev_x=0
 self.prev_y=0
 self.shkx=0
 self.shky=0
 self.circle_t=30
 self.circle_x=0
 self.circle_y=0
 self.jiggle=false
end)

function sqr(x) return x*x end

function cls_mouse:draw()
 local n=10
 
 update_shake(self)

 if self.jiggle then
  self.circle_t=1
  self.circle_x=glb_mouse_x
  self.circle_y=glb_mouse_y
  shake(self,3)
  -- cls(7)
  circfill(glb_mouse_x,glb_mouse_y,10,7)
  self.jiggle=false
 end

 for i=1,n do
  local idx=(self.idx+i-1)%n
  if self.trails[idx]!=nil then
   local v=self.trails[idx]
   local x=v[1]
   local y=v[2]
   local d=sqr(glb_mouse_x-x)+sqr(glb_mouse_y-y)
   darken((n-i)*100/n/2)
   if d>20 then
    local r=i/(n/3)+1
    -- circfill(v[1],v[2],r,7)
    spr(1,v[1],v[2])
   end
  end
 end
 pal()

 if self.circle_t<15 then
  -- self.circle_t+=2
  self.circle_t*=1.2
  circ(self.circle_x,self.circle_y,self.circle_t,7)
  darken((15-self.circle_t)/15*30+10)
  -- pal(7,5)
 end

 spr(1,glb_mouse_x+self.shkx,glb_mouse_y+self.shky)
 pal()


 -- if self.prev_x!=glb_mouse_x or self.prev_y!=glb_mouse_y then
  self.trails[self.idx]={glb_mouse_x,glb_mouse_y}
  self.idx=(self.idx+1)%n
 -- end
 self.prev_x=glb_mouse_x
 self.prev_y=glb_mouse_y
end

glb_mouse=cls_mouse.init()


resource_manager_cls=class(function(self)
 self.workers={}
 self.resources={}
 self.tabs={}
 self.money=0
end)

function resource_manager_cls:draw()
 local x=5
 local y=3

 for i,k in pairs(self.tabs) do
  if k.is_visible() then
   local button=k.button
   button.x=x
   button.y=y
   button:draw()
   x+=button.w+5
   if (glb_current_tab==k) k:draw()
  end
 end
 for _,k in pairs(self.resources) do
  k:draw()
 end
 for _,k in pairs(self.workers) do
  k:draw()
 end
 print("$"..tostr(self.money),104,3)
end

function resource_manager_cls:update()
 if glb_mouse_left_down then
  for _,resource in pairs(self.resources) do
   if resource:is_mouse_over() and resource:is_visible() then
    resource:on_click()
   end
  end
 end

 for _,resource in pairs(self.resources) do
  resource:update()
 end
 for _,worker in pairs(self.workers) do
  worker:update()
 end
end

glb_resource_manager=resource_manager_cls.init()

cls_tab=class(function(self, name)
 self.name=name
 self.button=cls_button.init(0,0,self.name)
 local button=self.button
 button.is_visible=function() return true end
 button.is_active=function() return glb_current_tab==self end
 button.on_hover=function()
   if glb_current_tab!=self then
    glb_dialogbox.visible=true
    glb_dialogbox.text={{7,"switch to "..self.name.." tab"}}
   end
 end
 button.on_click=function()
  if (glb_current_tab!=self) transition_tab(self)
 end
 button.should_blink=function()
  return button:is_mouse_over() and not button.is_active()
 end
 self.is_visible=function() return true end
end)

function cls_tab:draw()
end

cls_money_tab=subclass(cls_tab,function(self,name)
 cls_tab._ctr(self,name)
end)

function cls_money_tab:draw()
 local x=40
 local y=20

 self.current_hire_worker=nil

 for i,k in pairs(glb_hire_workers) do
  bstr(tostr(#k.workers).."x",x-28,y-1,7,0)
  spr(k.spr,x-12,y-2)
  k.button.y=y
  k.button.x=x
  k.button:draw()
  -- k.dismiss_button.y=y
  -- k.dismiss_button.x=x+60
  -- k.dismiss_button:draw()
  y+=k.button.h+7
 end
end

tab_game=cls_tab.init("office")
tab_release=cls_tab.init("release")
tab_release.is_visible=function()
 return res_build.created
end
tab_money=cls_money_tab.init("studio")
tab_money.is_visible=function()
 return glb_resource_manager.money>0 or #glb_resource_manager.workers>0
end

glb_resource_manager.tabs={tab_game,tab_release,tab_money}

function transition_tab(tab)
 add_cr(function()
  local w=8
  local w2=w*2
  for i=1,w,w/16 do
   yield()
   i=inoutexpo(i,0,w+1,w)
   for j=0,i do
    palt(0,false)
    for x=0,128/w2-1 do
     for y=0,128/w2-1 do
      -- rect(x*w2+j,y*w2+j,x*w2+w2-j,y*w2+w2-j,0)
      rect(x*w2+w-j,y*w2+w-j,x*w2+w+j,y*w2+w+j,0)
     end
    end
   end
   palt()
  end
   cls(7)
   yield()
  glb_current_tab=tab

 end,glb_draw_crs)
end
glb_current_tab=tab_game

resource_cls=class(function(self,
   name,
   full_name,
   x,y,
   dependencies,
   duration,
   spr,
   description,
   creation_text,
  tab)
 self.x=x
 self.y=y
 self.shkx=0
 self.shky=0
 self.name=name
 self.full_name=full_name
 self.dependencies=dependencies
 self.duration=duration
 self.t=0
 self.count=0
 self.created=false
 self.spr=spr
 self.description=description
 self.creation_text=creation_text
 self.is_clickable_f=function(self) return true end
 self.tab=tab
 glb_resource_manager.resources[name]=self
 self.last_explosion_time=0

 self.stat_t=0
 self.stat_produced=0
 self.offset=0

 if glb_debug then
  -- self.created=true
 end
end)

glb_resource_w=16

function resource_cls:shake(p)
 local a=rnd(1)
 self.shkx=cos(a)*p
 self.shky=sin(a)*p
end

function resource_cls:draw()
 if abs(self.shkx)+abs(self.shky)<1 then
  self.shkx=0
  self.shky=0
 end
 if glb_frame%4==0 then
  self.shkx*=-0.4-rnd(0.1)
  self.shky*=-0.4-rnd(0.1)
 end

 if (not self:is_visible()) return
 if ((not self.is_clickable_f()) or (not self:are_dependencies_fulfilled() and self.t==0)) darken(10)
 local x,y
 local w=glb_resource_w
 x,y=self:get_cur_xy()
 palt(0,false)
 palt(15,true)
 if self:is_mouse_over() then
  if frame(12,2)==0 then
   draw_rounded_rect2(x-1,y-1,w+2,w+2,glb_bg_col2,glb_bg_col2,7)
  else
   draw_rounded_rect2(x,y,w,w,glb_bg_col2,glb_bg_col2,7)
  end
 else
  draw_rounded_rect1(x,y,w,w,glb_bg_col2)
 end

 spr(self.spr+((frame(12,3)+self.offset)%3)*2,x,y,2,2)
 -- sspr(sx*8,sy*8,8,8,x,y,16,16)

 if self.t>0 then
  rectfill(x,y+w,x+self.t/self.duration*w,y+w+1,11)
 end
 pal()
 palt()
 print(tostr(self.count),x+2,y+w+4,7)

 if (self:is_mouse_over()) then
  glb_dialogbox.visible=true
  glb_dialogbox.text=self:get_display_text()
 end
end

function resource_cls:get_display_text()
 local result={
  {7,self.description}
 }
 local requirements={}
 local requires_col=7
 for n,v in pairs(self.dependencies) do
  local res=glb_resource_manager.resources[n]
  local col=7
  if v>res.count then
   col=5
   requires_col=5
  end
  requirements[#requirements+1]={col,"- "..tostr(max(1,v)).." "..(res.full_name)}
 end

 if #requirements>0 then
  result[#result+1]={requires_col,"requires:"}
  for _,v in pairs(requirements) do
   result[#result+1]=v
  end
 end

 return result
end

function resource_cls:get_cur_xy()
 local x=self.x*(glb_resource_w+6)+12
 local y=self.y*(glb_resource_w+3+10)+4+11
 return x+self.shkx,y+self.shky
end

function resource_cls:on_produced()
 if self.count<9999 then
  self.stat_produced+=1
  self.count+=1
 end
 self.created=true
 if self:is_visible() then
  local x,y
  x,y=self:get_cur_xy()
  local explode=(time()-self.last_explosion_time)>1
  make_pwrup_explosion(x-self.shkx+8,y-self.shky+9,explode)
  if (explode) self.last_explosion_time=time()
 end
 if (self.on_produced_cb!=nil) self.on_produced_cb(self)
 self:shake(2)

end

function resource_cls:start_producing()
  for n,v in pairs(self.dependencies) do
   local res=glb_resource_manager.resources[n]
   res.count-=v
  end
  if (self.on_produce_cb) self.on_produce_cb(self)
end

function resource_cls:produce()
 self:start_producing()
 self:on_produced()
end

function resource_cls:update()
 if self.t>0 then
  self.t+=glb_dt
  if self.t>(self.duration/glb_timescale) then
   self:on_produced()
   self.t=0
   glb_dialogbox:shake(4)
   -- shake dialog
   -- local text=self.creation_text
   -- cls_score_particle.init(mid(64-(#text/2)*4,5,80),95,text,0,7)
  end
 end

 self.stat_t+=glb_dt
 if self.stat_t>5 then
  -- printh(tostr(self.stat_produced).." "..self.name.." produced")
  self.stat_produced=0
  self.stat_t=0
 end
end

function resource_cls:are_dependencies_created()
 for n,_ in pairs(self.dependencies) do
  local res=glb_resource_manager.resources[n]
  if (not res.created) return false
 end
 return true
end

function resource_cls:is_visible()
 if (self.tab!=glb_current_tab) return false
 return self:are_dependencies_created()
end

function resource_cls:are_dependencies_fulfilled()
 for n,v in pairs(self.dependencies) do
  local res=glb_resource_manager.resources[n]
  if (res.count<v) return false
 end
 return true
end

function resource_cls:is_clickable()
 return self.t==0 and self:are_dependencies_fulfilled() and self.is_clickable_f()
end

function resource_cls:on_click()
 if self:is_clickable() then
  glb_mouse.jiggle=true
  self:start_producing()
  self.t=glb_dt
 end
end

function resource_cls:is_mouse_over()
 local x,y
 x,y=self:get_cur_xy()
 local dx=glb_mouse_x-x
 local dy=glb_mouse_y-y
 return dx>=0 and dx<=glb_resource_w and dy>=0 and dy<=glb_resource_w
end

res_loc=resource_cls.init(
  -- name
  "loc",
  -- full_name
  "lines of code",
  -- position
  0,0,
  -- dependencies
  {},
  -- duration
  0.3,
  -- spr
  4,
  -- description
  "write a line of code!",
  "line of code written",
  tab_game
)
res_loc.active=true

res_func=resource_cls.init(
"func",
"c# functions",
 1,0,
 {loc=5},
 0.5,
  -- spr
  106,
  -- description
  "write a c# function!",
  "c# function written",
  tab_game
)

res_csharp_file=resource_cls.init(
 "csharp_file",
 "c# files",
 2,0,
 {func=5},
 1,
 -- spr
 4,
 -- description
 "write a c# file!",
 "c# file written",
 tab_game
)

res_contract_work=resource_cls.init(
 "contract",
 "contract work",
 3,0,
 {csharp_file=2},
 2,
 -- spr
 132,
 -- description
 "do client work (+$10)",
 "",
 tab_game
)
res_contract_work.on_produced_cb=function(self)
 glb_resource_manager.money+=10
 if (self:is_visible()) make_score_particle_explosion("$",5,83,20,11,3)
end

--
res_pixel=resource_cls.init("pixel",
 "pixels",
  0,1,
  {},
  0.3,
  -- spr
  36,
  -- description
  "draw a pixel!",
  "pixel drawn",
  tab_game
)

res_sprite=resource_cls.init("sprite",
 "sprites",
  1,1,
  {pixel=8},
  0.8,
  -- spr
  202,
  -- description
  "draw a sprite!",
  "sprite drawn",
  tab_game
)

res_animation=resource_cls.init("animation",
 "animations",
 2,1,
 {sprite=4},
 1,
 74,
 "make an animation",
 "animation created",
 tab_game
)

res_prop=resource_cls.init("prop",
 "props",
 3,1,
 {animation=1,csharp_file=1},
 2,
 -- spr
 138,
 "make a prop!",
 "prop created",
 tab_game
)

res_character=resource_cls.init("character",
 "characters",
 4,1,
 {animation=2,csharp_file=1},
 6,
 -- spr
 74,
 "make a character!",
 "character created",
 tab_game
)
res_character.offset=1

res_tilemap=resource_cls.init("tilemap",
 "tilemaps",
 0,2,
 {sprite=4},
 2,
 -- spr
 36,
 "make a tilemap!",
 "tilemap created",
 tab_game
)

---

res_level=resource_cls.init("level",
 "levels",
 1,2,
 {tilemap=1,prop=5,character=2,csharp_file=1},
 5,
 -- spr
 164,
 "make a level!",
 "level created",
 tab_game
)

res_build=resource_cls.init(
 "build",
 "game builds",
 2,2,
 {level=5},
 2,
 -- spr
 4,
 -- description
 "make a beta build",
 "game built",
 tab_game
)

res_playtest=resource_cls.init(
 "playtest",
 "playtests",
 3,2,
 {build=0},
 .5,
 -- spr
 42,
 -- description
 "playtest the beta build",
 "game tested",
 tab_game
)
res_playtest.offset=1
res_playtest.is_clickable_f=function(self)
 return res_build.count>0
end

res_release=resource_cls.init(
 "release",
 "releases",
 4,2,
 {build=5,playtest=100},
 10,
 -- spr
 42,
 -- description
 "make a release",
 "game released",
 tab_game
)

-- release resources

res_tweet=resource_cls.init(
 "tweet",
 "tweets",
 0,0,
 {build=0},
 0.5,
 -- spr
 100,
 -- description
 "write a tweet",
 "tweet written",
 tab_release
)

res_youtube=resource_cls.init(
 "youtube",
 "youtube videos",
 1,0,
 {build=0},
 3,
 -- spr
 68,
 -- description
 "produce a youtube video",
 "youtube video recorded",
 tab_release
)

res_twitch=resource_cls.init(
 "twitch",
 "twitch streams",
 2,0,
 {build=0},
 3,
 -- spr
 10,
 -- description
 "produce a twitch stream",
 "twitch stream recorded",
 tab_release
)

res_gamer=resource_cls.init(
 "gamer",
 "gamers",
 0,1,
 {tweet=5,youtube=5,twitch=5,build=0},
 3,
 -- spr
 74,
 -- description
 "recruit a gamer",
 "gamer recruited",
 tab_release
)
res_gamer.on_produced_cb=function(self)
 glb_hire_gamer:hire()
end

cls_worker=class(function(self,duration)
 self.t=0
 self.orig_duration=duration/glb_timescale
 self.duration=self.orig_duration
 self.spr=64
 self.y=120
 self.spd_y=0
 self.x=flr(rnd(120))
 self.spd_x=rnd(0.2)+0.2
 self.dir=1
 self.state=0 -- 0=walking, 1=jumping
 self.auto_resources={}
 self.default_resource=nil
 self.tab=nil
 self.cost=0
 self.hire_worker=nil
 self.no_salary_t=0
end)

function cls_worker:update()
 self.t+=glb_dt

 if (self.no_salary_t>0) self.no_salary_t+=glb_dt

 if self.t>self.duration then
  self.duration=self.orig_duration
  self.t=0
  if glb_resource_manager.money>=self.cost or self.hire_worker.name=="coder" then
   self:on_tick()
   self.no_salary_t=0
   glb_resource_manager.money-=self.cost
  else
   if (self.no_salary_t==0) self.no_salary_t=glb_dt

   if self.no_salary_t>10 and maybe(0.1) then
    self.hire_worker:dismiss(self)
    self:show_text("i quit!!",8,7)
    cls_score_particle.init(mid(24+5,5,80),64+8,
     "a "..self.hire_worker.name.." left",0,7)
   else
    self:show_text("$$$!",8,7)
   end
  end
 end

 self.x+=self.dir*self.spd_x
 self.y+=self.spd_y
 if self.y>120 then
  self.y=120
  self.spd_y=0
 end
 if self.spd_y!=0 then
  self.spd_y+=0.18
 end
 if (self.x<0 or self.x>120) self.dir*=-1
 if (maybe(1/200)) self.dir*=-1
end

function cls_worker:draw()
 if self:is_visible() then
  spr(self.spr+frame(8,2),self.x,self.y,1,1,self.dir<0)
  -- spr(self.spr+frame(8,3),self.x,120,8,8,self.dir>0)
 end
end

function cls_worker:is_visible()
 if glb_current_tab==tab_money then
  if tab_money.current_hire_worker!=nil then
   return getmetatable(self)==tab_money.current_hire_worker.cls
  else
   return true
  end
 else
  return self.tab==glb_current_tab
 end
end

function cls_worker:on_tick()
 local res=self.default_resource
 local max_requirements={}
 for _,v in pairs(self.auto_resources) do
  if v:are_dependencies_created() then
   for name,dep in pairs(v.dependencies) do
    if (max_requirements[name]~=nil) max_requirements[name]=dep
    max_requirements[name]=max(dep,max_requirements[name])
   end
  end
 end

 local potential_resources={}

 for _,v in pairs(self.auto_resources) do
  if v:are_dependencies_fulfilled() then
   local add_res=true
   for name,dep in pairs(v.dependencies) do
    if max_requirements[name]!=nil and glb_resource_manager.resources[name].count<max_requirements[name] then
     add_res=false
    end
   end
   if (add_res) add(potential_resources,v)
  end
 end


 if #potential_resources>0 and maybe(0.2) then
  local min_count=1000
  for _,k in pairs(potential_resources) do
   if k.count<min_count then
    res=k
    min_count=k.count
   elseif k.name=="contract" and maybe(0.3) then
    res=k
    break
   end
  end
 end

 if (res==nil) return

 res:produce()
 self.spd_y=-1.5+mrnd(0.75)
 
 self.duration=max(self.orig_duration,res.duration)
 if self:is_visible() then
  local text=rnd_elt({"wow","ok","!!!","yeah","boom","kaching","lol","haha"})
  self:show_text(text,0,7)
 end
end

function cls_worker:show_text(text,fg,bg)
  cls_score_particle.init(self.x-(#text/2),self.y-5,text,fg,bg)
end

spr_coder=64
coder_auto_resources={res_func,res_csharp_file,res_contract_work}
coder_salary=0.05
cls_coder=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.default_resource=res_loc
 self.tab=tab_game
 self.duration/=2
end)

spr_gfx_artist=80
gfx_artist_salary=0.05
gfx_artist_auto_resources={res_tilemap,res_sprite,res_animation}
cls_gfx_artist=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.default_resource=res_pixel
 self.tab=tab_game
end)

spr_game_designer=96
game_designer_auto_resources={res_prop,res_character,res_level}
game_designer_salary=0.1
cls_game_designer=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.tab=tab_game
end)

spr_tweeter=96
tweeter_salary=0.1
tweeter_auto_resources={res_tweet}
cls_tweeter=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.tab=tab_release
end)

spr_youtuber=64
youtuber_salary=0.1
youtuber_auto_resources={res_youtube}
cls_youtuber=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.tab=tab_release
end)

spr_twitcher=80
twitcher_salary=0.2
twitcher_auto_resources={res_twitch}
cls_twitcher=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.tab=tab_release
end)

spr_gamer=80
gamer_auto_resources={res_playtest}
cls_gamer=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.auto_resources={}
 self.spr=spr_gamer
 self.tab=tab_release
end)

function cls_gamer:is_visible()
 return glb_current_tab!=tab_money
end

function cls_gamer:on_tick()
 cls_worker.on_tick(self)
 local money=1+(res_release.count-1)*0.5
 glb_resource_manager.money+=money
 if (self:is_visible()) make_score_particle_explosion("$",flr(money)+1,self.x,116,11,3,5,2)
end

cls_hire_worker=class(function(self,name,cls,dependencies,spr,cost,auto_resources,salary)
 self.cls=cls
 self.name=name
 self.workers={}
 self.dependencies=dependencies
 self.spr=spr
 self.cost=cost
 self.salary=salary
 self.auto_resources=auto_resources

 self.button=cls_button.init(0,0,self.name)
 local button=self.button
 button.blink_on_hover=true
 button.w=54
 button.h=5

 button.is_active=function() return self:is_hireable() end
 button.is_visible=function() return true end
 button.on_hover=function()
  tab_money.current_hire_worker=self
  if button.is_active() then
   glb_dialogbox.visible=true
   glb_dialogbox.text=self:get_display_text()
  end
 end
 button.on_click=function()
  if self:is_hireable() then
   self:hire()
   glb_mouse.jiggle=true
   make_pwrup_explosion(glb_mouse_x,glb_mouse_y,true)
  end
 end
 button.should_blink=function()
  return button.is_active() and button:is_mouse_over()
 end

 self.dismiss_button=cls_button.init(0,0,"dismiss")
 local dismiss_button=self.dismiss_button
 dismiss_button.w=29
 dismiss_button.h=5

 dismiss_button.is_visible=function()
  return #self.workers>0
 end
 dismiss_button.is_active=dismiss_button.is_visible
 dismiss_button.should_blink=function() return dismiss_button:is_mouse_over() end
 dismiss_button.on_click=function()
  cls_score_particle.init(mid(glb_mouse_x+5,5,80),glb_mouse_y+8,
   "dismissed a "..self.name,0,7)
  self:dismiss()
 end
 dismiss_button.on_hover=function()
  glb_dialogbox.visible=true
  glb_dialogbox.text={{7,"dismiss "..self.name}}
 end
end)

function cls_hire_worker:hire()
 local w=self.cls.init(2+rnd(2))
 glb_resource_manager.money-=self.cost
 w.auto_resources=self.auto_resources
 w.cost=self.salary
 w.hire_worker=self
 add(self.workers,w)
 add(glb_resource_manager.workers,w)
 glb_dialogbox:shake(5)
 w.spr=self.spr
end

function cls_hire_worker:is_hireable()
 if (glb_resource_manager.money<self.cost) return false
 for k,v in pairs(self.dependencies) do
  local res=glb_resource_manager.resources[k]
  if (not res.created or res.count<v) return false
 end
 return true
end

function cls_hire_worker:dismiss(worker)
 if #self.workers>0 and worker==nil then
  worker=self.workers[1]
 end

 if worker!=nil then
  del(self.workers,worker)
  del(glb_resource_manager.workers,worker)
 end
end

function cls_hire_worker:get_display_text()
 local result={
  {7,"hire a "..self.name},
  {7,"cost: $"..tostr(self.cost)},
  {7,"salary: $"..tostr(self.salary)},
  {7,"produces:"}
 }

 for _,resource in pairs(self.auto_resources) do
  add(result,{7,"- "..resource.full_name})
 end

 return result
end

glb_hire_workers={
 cls_hire_worker.init(
  "coder",cls_coder,{},spr_coder,5,
  coder_auto_resources,
  coder_salary
 ),
  cls_hire_worker.init(
  "artist",cls_gfx_artist,{},spr_gfx_artist,10,
  gfx_artist_auto_resources,
  gfx_artist_salary
 ),
 cls_hire_worker.init(
  "game designer",cls_game_designer,{},spr_game_designer,10,
  game_designer_auto_resources,
  game_designer_salary
 ),
 cls_hire_worker.init(
  "tweeter",cls_tweeter,{build=0},spr_tweeter,10,
  tweeter_auto_resources,
  tweeter_salary
 ),
 cls_hire_worker.init(
  "youtuber",cls_youtuber,{build=0},spr_youtuber,10,
  youtuber_auto_resources,
  youtuber_salary
 ),
 cls_hire_worker.init(
  "twitcher",cls_twitcher,{build=0},spr_twitcher,10,
  twitcher_auto_resources,
  twitcher_salary
 )
}

glb_hire_gamer=cls_hire_worker.init(
 "gamer",cls_gamer,{},spr_gamer,0,
 gamer_auto_resources,
 0
)


function _init()
 poke(0x5f2d,1)
 if glb_debug then
  res_loc.count=1000
  glb_timescale=1
  glb_resource_manager.money=1000
  res_csharp_file.count=1000
  res_csharp_file.created=true
  res_level.count=50
  res_level.created=true
  res_build.created=true
  res_build.count=5
  res_playtest.count=200
  res_playtest.created=true
  res_youtube.created=true
  res_twitch.created=true
  res_tweet.created=true
  res_youtube.count=5
  res_twitch.count=5
  res_tweet.count=5
 else
  glb_resource_manager.money=0
 end
end

glb_lasttime=time()
glb_dt=0
glb_frame=0

glb_mouse_x=0
glb_mouse_y=0
glb_prev_mouse_btn=0
glb_mouse_left_down=false
glb_mouse_right_down=false

glb_bg_col=1
glb_bg_col2=12

function set_mouse()
 local mouse_btn=stat(34)
 glb_mouse_left_down=band(glb_prev_mouse_btn,1)!=1 and band(mouse_btn,1)==1
 glb_mouse_right_down=band(glb_prev_mouse_btn,2)!=2 and band(mouse_btn,2)==2
 glb_prev_mouse_btn=mouse_btn

 glb_mouse_x=stat(32)
 glb_mouse_y=stat(33)
end

function _draw()
 set_mouse()
 glb_frame+=1
 cls(glb_bg_col)

 for _,v in pairs(glb_pwrup_particles) do
  v:draw()
 end

 glb_resource_manager:draw()
 glb_mouse:draw()

 for _,v in pairs(glb_particles) do
  v:draw()
 end

 glb_dialogbox:draw()

 tick_crs(glb_draw_crs)
end

function _update60()
 glb_dialogbox.visible=false
 glb_dt=time()-glb_lasttime

 glb_lasttime=time()
 glb_resource_manager:update()
 tick_crs(glb_crs)

 for _,v in pairs(glb_pwrup_particles) do
  v:update()
 end

 for _,v in pairs(glb_particles) do
  v:update()
 end
end


__gfx__
0000000077777770000000000000000033ffbbbf33ffbbbfbbbf33ffbbbf33ff33ffbbbfbbff333fcccccccccccccccccccccccccccccccccccccccccccccccc
00000000766667000000000000000000f3ffbfbff3ffbfbfbfbff3ffbfbff3fff3ffbfbffbff3f3fcccccccccccccccccc777777777777cccccccccccccccccc
007007007d6670000000000000000000f3ffbfbff3ffbfbfbfbff3ffbfbff3fff3ffbfbffbff3f3fcc777777777777cccc7dddddddddd7cccc777777777777cc
000770007dd667000000000000000000f3ffbfbff3ffbfbfbfbff3ffbfbff3fff3ffbfbffbff3f3fcc7dddddddddd7cccc7dddddddddd7cccc7dddddddddd7cc
000770007d7d66700000000000000000333fbbbf333fbbbfbbbf333fbbbf333f333fbbbfbbbf333fcc7dddddddddd7cccc7dd77dd77dd7cccc7dddddddddd7cc
007007007707d6670000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffcc7ddd77dd77d7cccc7dd77dd77dd7cccc7dd77dd77dd7cc
0000000070007d700000000000000000777777776ff76666777777776ff76666777777776ff76666cc7ddd77dd77d7cccc7dd77dd77dd7cccc7dd77dd77dd7cc
00000000000007000000000000000000700000076676666570000007667666657000000766766665cc7ddd77dd77d7cccc7dd77dd77dd7cccc7dd77dd77dd7cc
555555558888888800000000000000007008b007667777557008b007667777557008b00766777755cc7ddd77dd77d7cccc7dddddddddd7cccc7dd77dd77dd7cc
50000005502605550000000000000000700ca00766777755700ca00766777755700ca00766777755cc7dddddddddd7cccc7dddddddddd7cccc7dddddddddd7cc
5000000552aa65950000000000000000700000076676675570000007667667557000000766766755cc7dddddddddd7cccc7dddddddddd7cccc7dddddddddd7cc
500000055aaa1565000000000000000070b3300766777755703b3007667777557033b00766777755cc7dddddddddd7cccc777777777777cccc7dddddddddd7cc
50000005501105e50000000000000000777777776677775577777777667777557777777766777755cc777777777777cccccccc777ccccccccc777777777777cc
55555555555555550000000000000000666668636f778755666668636f7787556666686b6f778755cccccc777ccccccccccccc77cccccccccccccc777ccccccc
bbb55bbb6e0000000000000000000000fff555ffff777756fff555ffff777756fff555ffff777756cccccc77cccccccccccccccccccccccccccccc77cccccccc
bb5555bb000000000000000000000000f7776666ff77776ff7776666ff77776ff7776666ff77776fcccccccccccccccccccccccccccccccccccccccccccccccc
66666666000000000000000000000000ddddfddddfddddffddddfddddfddddffddddfddddfddddffffffffffffffffffffffffffffffffffffffffffffffffff
600000060000000000000000000000006788d6700d6700df6788d6799d67aadf6788d6799d67aadfffffffffffffffffffffffffffffffffffffffffffffffff
600000060000000000000000000000006888d600000000df6888d6999000aadf6888d6999000aadffff0005ff0005fffffffffffffffffffffffffffffffffff
600000060000000000000000000000006888d600077700df6888d69907770adf6888d69907770adfff000000000000fffff0005ff0005fffffffffffffffffff
600000060000000000000000000000006666d660744470df6666d660744470df6666d660744470dfff05500dd00008ffff000000000000fffff0005ff0005fff
66666666000000000000000000000000ddddfd0744470dffddddfd0744470dffddddfd0744470dffff0550066000c0ffff05500dd00008ffff000000000000ff
bbb66bbb0000000000000000000000006700d074444700df6700d074444700df67bbd074444701dfff000050000000ffff0550066000c0ffff05500dd00008ff
bb6666bb0000000000000000000000006000d074444700df6000d074444700df6bbbd074444701dff00000500550000fff000050000000ffff0550066000c0ff
888888880000000000000000000000006000d074447000df6000d074447000df6bbbd074447011dff00000000000000ff00000500550000fff000050000000ff
50ee05550000000000000000000000006666d607457066df6666d607457066df6666d607457066dff00005ffff00000ff00000000000000ff00000500550000f
5eeee595000000000000000000000000ddddfd0755570dffddddfd0755570dffddddfd0755570dfff0000ffffff0005ff00005ffff00000ff00000000000000f
5eeee565000000000000000000000000ffffd6707d5570ffffffd6707d5570ffffffd6707d5570ffff005ffffff005fff0000ffffff0005ff00005ffff00000f
50ee05a5000000000000000000000000ffffd60007d5570fffffd60007d5570fffffd62207d5570fffffffffffffffffff005ffffff005fff0000ffffff0005f
55555555000000000000000000000000ffffd600007d5570ffffd600007d5570ffffd622207d5570ffffffffffffffffffffffffffffffffff005ffffff005ff
6e0c0000000000000000000000000000ffffd6666d07d557ffffd6666d07d557ffffd6666d07d55fffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000fffffddddff07d55fffffddddff07d55fffffddddff07d55ffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000008855550000000000777777777777777777777777777777777777777777777777ffff888888ffffffffffffffffffffffffff888888ffffff
85555000000000000056667000000000777777777777777777777777777777777777777777777777ffff888888ffffffffffffffffffffffffff888888ffffff
85666000085555000051117000000000777777777777777777788888888887777777777777777777ff888877888888ffffff88888877ffffff888877888888ff
05111700085666700dd6167000000000777888888888877777888888888888777777888888887777ff888877888888ffffff88888877ffffff888877888888ff
05616700005111700dd5550000000000778888888888887777888778888888777778888888888777ff888888888877ffff888877888888ffff888888888877ff
dd5557000dd616700005500000000000778887788888887777888777788888777778887888888777ff888888888877ffff888877888888ffff888888888877ff
dd5500000dd550000060060000000000778887777888887777888777777888777778887778888777ff778888778888ffff888888888877ffff778888778888ff
00660000000606000000000000000000778887777778887777888777777788777778887777788777ff778888778888ffff888888888877ffff778888778888ff
00888700000000000088870000000000778887777777887777888777777888777778887778888777ffff44bb44bbffffff778888778888ffffff44bb44bbffff
08878880008887000887888000000000778887777778887777888777788888777778887888888777ffff44bb44bbffffff778888778888ffffff44bb44bbffff
08888870088788800888887000000000778887777888887777888778888888777778888888888777ffff99999999ffffffff44bb44bbffffffffff9999ffffff
07887880088888700788788000000000778887788888887777888888888888777777888888887777ffff99999999ffffffff44bb44bbffffffffff9999ffffff
004b4b0007887880004b4b0000000000778888888888887777788888888887777777777777777777ffffff9999ffffffffffff9999ffffffffff99ffff99ffff
00ffff00004b4b00000ff00000000000777888888888877777777777777777777777777777777777ffffff9999ffffffffffff9999ffffffffff99ffff99ffff
000ff000000ff00000f00f0000000000777777777777777777777777777777777777777777777777ffffff9999ffffffffffff99ff99ffffffffffffffffffff
000ff000000f0f000000000000000000777777777777777777777777777777777777777777777777ffffff9999ffffffffffff99ff99ffffffffffffffffffff
00000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccf76fffffffffffff776ff8882ffffffff76ff8882fffffff
44044400000000004404440000000000ccccccccc77cccccccccccccc7cccccccccccccccccccccc776ff8882ffffffff76ff8882ffffffff76ff8882fffffff
40447770440444004044777000000000cccccccc7cccccccccccccccc7ccccccccccccccc77cccccf76ff8882ffffffff76ff8882fffffff7776f8882f77776f
40445750404477700044575000000000c7cccccc7777cccccccc7ccc7ccccccccccccccc7cccccccf76ff8882fffffff7776f8882f77776fffffffffffffffff
00077770404457500007777000000000c77cccc777777cccccc7cccc7777cccccccccccc7777cccc7776f8882f77776fffffffffffffffff7776ffffffffffff
0000ee00000777700000880000000000c7777cc7777c77cccc777cc777777ccccc7cccc777777cccffffffffffffffff7776ffffffffffffff76fbbb3fffffff
00008800000088000007007000000000cc777777777777c7cc7777c7777c77cccc777cc7777c77cc7776ffffffffffffff76fbbb3fffffff7776fbbb3fffffff
00007700000070700000000000000000cc7777777777777cccc77777777777cccc777777777777c7ff76fbbb3fffffff7776fbbb3fffffff76fffbbb3fffffff
77777770d11110000000000000000000ccc7777777777777ccc7777777777777cc7777777777777c7776fbbb3fffffff76fffbbb3fffffff7776fbbb3f77776f
76666700d11100000000000000000000cccc7777777777cccccc777777777777ccc777777777777776fffbbb3fffffff7776fbbb3f77776fffffffffffffffff
7d667000d111100000000000000000007cccc777777777cccccc7777777777cccccc7777777777cc7776fbbb3f77776fffffffffffffffff7776ffffffffffff
7dd66700d11111000000000000000000c777777777777cccccccc777777777ccc7ccc777777777ccffffffffffffffff7776ffffffffffffff76faaa9fffffff
7d7d6670d1d111100000000000000000cc7777777777cccc7777777777777cccc777777777777ccc7776ffffffffffffff76faaa9ffffffff776faaa9fffffff
7707d667000d11110000000000000000cccc777777cccccccc7777777777cccccc7777777777ccccff76faaa9ffffffff776faaa9fffffffff76faaa9fffffff
70007d700000d1100000000000000000cccccccccccccccccccc777777cccccccccc777777ccccccf776faaa9fffffffff76faaa9fffffff7776faaa9f77776f
0000070000000d000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccff76faaa9fffffff7776faaa9f77776fffffffffffffffff
00000000000000000000000000000000ffffffffffffbb3ffff7776ffffbb3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
04440004440004440000000000000000fff7776ffffb3fb3ff500506ffb3fb3fffffffffffffbb3fffffffffffffffffffffffffffffffffffffffffffffffff
00f0000cfc0000400000000000000000ff500506fffb3fffff007006ffb3fffffff7776ffffb3fb3fff444444444ffffffffffffffffffffffffffffffffffff
0fff000fff0004440000000000000000ff007006ffffbb3fff777776fffbb3ffff500506fffb3fffff4a999942224fffffffffffffffffffffffffffffffffff
33f33067776017871000000000000000ff777776ffffffb3fff7776ffffffb3fff007006ffffbb3fff445444442224fffff4444444444fffffffffffffffffff
f333f0f777f041814000000000000000fff7776ffffb3fb3f77777776fb3fb3fff777776ffffffb3ffff54111142224fff4a9999422224fffffff444444fffff
02920005550001110000000000000000f77777776fffbb3f7777777776fbb3fffff7776ffffb3fb3ffffff411114224fff445444444224fffff44a9942244fff
010100050500010100000000000000007777777776ffffff7777777776ffffff777777776fffbb3ffffffff41111424ffffffff41114224fff4a9999422224ff
010100050500010100000000000000007777777776ffbb3f7777777776ffffff7777777776fffffff44444444444444ff44444444444444ff44444444444444f
000000000000000000000000000000007777777776fb3fb37777777776ffbb3f7777777776fbb3fff4a909994222224ff4a909994222224ff4a909994222224f
000000000000000000000000000000006777777766fb3fff6777777766fb3fb37777777776b3fb3ff4a909994222224ff4a909994222224ff4a909994222224f
00000000000000000000000000000000f77777776fffbb3ff77777776ffb3fff6777777766b3fffff4a999994222224ff4a999994222224ff4a999994222224f
00000000000000000000000000000000f77777776fffffb3f77777776fffbb3ff77777776ffbb3fff4a999994222224ff4a999994222224ff4a999994222224f
00000000000000000000000000000000f77767776ffb3fb3f77767776fffffb3f77767776ffffb3ff44444444444444ff44444444444444ff44444444444444f
00000000000000000000000000000000f77767776fffbb3ff77767776ffb3fb3f77767776fb3fb3fffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ffffffffffffffffffffffffffffbb3ffffffffffffbb3ffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000f66666666666666ff66666666666666ff66666666666666fffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000f6ffffffffffff6ff6fff6ffffffff6ff6fff6ffffffff6ffffffffffffffffffffffffff7777fffffffffffffffffff
00000000000000000000000000000000f6ffffffffffff6ff6f66666f6666f6ff6f66666f6666f6ffffffffff7777fffffffffff7ffff7ffffffffffffffffff
00000000000000000000000000000000f6ffffffffffff6ff6f6ffffffff6f6ff6f6ffffffff6f6fffffffff7ffff7fffffffff7f7777f7ffffffffff7777fff
00000000000000000000000000000000f6ffffffffffff6ff6f6ffffffff6f6ff6f6f666666f6f6ffffffff7f7777f7ffffffff7f7777f7fffffffff7ffff7ff
00000000000000000000000000000000f6ffffffffffff6ff6ffffffffff6f6ff6fff6ff6f6f6f6ffffffff7f7777f7ff7fffff7f7777f7ffffffff7f7777f7f
00000000000000000000000000000000f6ffffffffffff6ff6f6ffffffff666ff6f6f6f66fff666ff7fffff7f7777f7f77fffff7f7777f7ffffffff7f7777f7f
00000000000000000000000000000000f6ffffffffffff6ff6f6ffffffff6f6ff6f6f6f66f6f6f6f77fffff7f7777f7ff77fff777ffff7fff7fffff7f7777f7f
00000000000000000000000000000000ffffffffffffff6ffff6ffffffff6f6ffff666ffff6f6f6ff77fff777ffff7ffff77f77777777fff77fffff7f7777f7f
00000000000000000000000000000000f6ffffffffffff6ff6f6ffffffff6f6ff6f6f666666f6f6fff77f77777777ffffff77ff77ffffffff77fff777ffff7ff
00000000000000000000000000000000f6ffffffffffff6ff6f6ffffffff6f6ff6f6ffffffff6f6ffff77ff77fffffffffff7ff7ffffffffff77f77777777fff
00000000000000000000000000000000f6fffffffffffffff6f66666f6666ffff6f66666f6666fffffff7ff7fffffffffffff77ffffffffffff77ff77fffffff
00000000000000000000000000000000f6ffffffffffff6ff6ffffffffffff6ff6ffffffffffff6ffffff77fffffffffffffffffffffffffffff7ff7ffffffff
00000000000000000000000000000000f66666666666666ff66666666666666ff66666666666666ffffffffffffffffffffffffffffffffffffff77fffffffff
00000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000fbbffbbfbbffbbbffbbffbbfbbffbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000bfffbfbfbfbfbfffbfffbfbfbfbfbfffffffffffffffffffffffffffffffffffff8855555555ffffff8855555555ffff
00000000000000000000000000000000bfffbfbfbfbfbbffbfffbfbfbfbfbbffffffffffffffffffffffffffffffffffff8855555555ffffff8855555555ffff
00000000000000000000000000000000bfffbfbfbfbfbfffbfffbfbfbfbfbfffffffffffffffffffffffffffffffffffff8855666666ffffff8855666666ffff
00000000000000000000000000000000fbbfbbffbbbfbbbffbbfbbffbbbfbbbfffffffffffffffffffffffffffffffffff8855666666ffffff8855666666ffff
00000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5511111177ffffff5511111177ff
00000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5511111177ffffff5511111177ff
00000000000000000000000000000000fffffff99999ffffffffbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5566116677ff
00000000000000000000000000000000fffaaaaaaaaaaffffffbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5566116677ff
00000000000000000000000000000000ff999999999aaffffffbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdddd55555577ff
00000000000000000000000000000000ff999999999aaffffffbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdddd55555577ff
00000000000000000000000000000000fff999999999afffffbfffbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffdddd5555ffffff
00000000000000000000000000000000fff999999999afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdddd5555ffffff
00000000000000000000000000000000ffff999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6666ffffff
00000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6666ffffff
00000000000000000000000000000000fff7776ffffb3ffffbbffbbfbbffbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ff777776ffbb3fffbfffbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ff777776fbbbbbb3bfffbfbfbfbfbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ff777776ffbb3fb3bfffbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000fff7776ffffb3fb3fbbfbbffbbbfbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000f77777776fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
000000000000000000000000000000007777777776fffffffbb3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
000000000000000000000000000000007777777776ffbbb3ffb3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
000000000000000000000000000000007777777776ffbbb3ffb3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
000000000000000000000000000000007777777776ffbbb3fbbb3fbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000fffffffffffffbb3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ffffffffffffbbb3fbbb3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000fffffffffffbbb3ffffb3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000fffffffffbbbb3fffbbb3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ffffffffbbbb3ffffb3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000ffffffffbbb3fffffbbb3fbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
