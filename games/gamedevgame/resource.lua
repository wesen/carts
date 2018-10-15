resource_cls=class(function(self,
   name,
   full_name,
   x,y,
   dependencies,
   duration,
   spr,
   description,
   creation_text)
 self.x=x
 self.y=y
 self.name=name
 self.full_name=full_name
 self.dependencies=dependencies
 self.duration=duration
 self.t=0
 self.count=0
 self.active=false
 self.created=false
 self.spr=spr
 self.description=description
 self.creation_text=creation_text
 glb_resource_manager.resources[name]=self
end)

glb_timescale=1
glb_resource_w=16

function resource_cls:draw()
 if (not self:is_visible()) return
 if (not self:are_dependencies_fulfilled() and self.t==0) darken(10)
 local x,y
 local w=glb_resource_w
 x,y=self:get_cur_xy()
 palt(0,false)
 palt(11,true)
 if self:is_mouse_over() then
  draw_rounded_rect2(x,y,w,glb_bg_col2,glb_bg_col2,7)
 else
  draw_rounded_rect1(x,y,w,glb_bg_col2)
 end

 local spage=flr(self.spr/64)
 local sy=flr(self.spr/16)
 local sx=self.spr%16
 sspr(sx*8,sy*8,8,8,x,y,16,16)
 if self.t>0 then
  rectfill(x,y+w,x+self.t/self.duration*w,y+w+1,11)
 end
 print(tostr(self.count),x+2,y+w+3,7)

 if (self:is_mouse_over()) then
   print(self:get_display_text(),32,80,7)
  end
 pal()
 palt()
end

function resource_cls:get_display_text()
 local txt=self.description
 local txt2=""
 for n,v in pairs(self.dependencies) do
  local res=glb_resource_manager.resources[n]
  txt2=txt2.."- "..tostr(v).." "..(res.full_name).."\n"
 end

 if txt2!="" then
  txt=txt.."\nrequires:\n"..txt2
 end

 return txt
end

function resource_cls:get_cur_xy()
 local x=self.x*(glb_resource_w+4)+2
 local y=self.y*(glb_resource_w+3+8)+2
 return x,y
end

function resource_cls:update()
 if self.t>0 then
  self.t+=glb_dt
  if self.t>(self.duration/glb_timescale) then
   self.count+=1
   self.created=true
   self.t=0
   local x,y
   x=64
   y=64
   cls_score_particle.init(x-4*(#self.creation_text/2),y+8,self.creation_text,0,7)
  end
 end
end

function resource_cls:is_visible()
 for n,_ in pairs(self.dependencies) do
  local res=glb_resource_manager.resources[n]
  if (not res.created) return false
 end
 return true
end

function resource_cls:are_dependencies_fulfilled()
 for n,v in pairs(self.dependencies) do
  local res=glb_resource_manager.resources[n]
  if (res.count<v) return false
 end
 return true
end

function resource_cls:is_clickable()
 return self.t==0 and self:are_dependencies_fulfilled()
end

function resource_cls:on_click()
 if self:is_clickable() then
  for n,v in pairs(self.dependencies) do
   local res=glb_resource_manager.resources[n]
   res.count-=v
  end
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
