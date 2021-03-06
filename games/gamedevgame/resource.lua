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
   glb_dialogbox:shake(3)
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
