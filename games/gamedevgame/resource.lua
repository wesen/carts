resource_cls=class(function(self,
   name,
   x,y,
   dependencies,
   duration,
   spr,
   description)
 self.x=x
 self.y=y
 self.name=name
 self.dependencies=dependencies
 self.duration=duration
 self.t=0
 self.count=0
 self.active=false
 self.created=false
 self.spr=spr
 self.description=description
 glb_resource_manager.resources[name]=self
end)

glb_resource_w=16

function resource_cls:draw()
 if (not self:is_visible()) return
 if (not self:are_dependencies_fulfilled()) darken(50)
 local x,y
 x,y=self:get_cur_xy()

 local spage=flr(self.spr/64)
 local sy=flr(self.spr/16)
 local sx=self.spr%16
 sspr(sx*8,sy*8,8,8,x,y,16,16)
 print(tostr(self.count),x+2,y+glb_resource_w+2,7)

 if (self:is_mouse_over()) print(self.name,32,80,7)
 pal()
end

function resource_cls:get_cur_xy()
 local x=self.x*(glb_resource_w+2)
 local y=self.y*(glb_resource_w+2+8)
 return x,y
end

function resource_cls:update()
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

function resource_cls:on_click()
 if self:are_dependencies_fulfilled() then
  self.count+=1
  self.created=true
  for n,v in pairs(self.dependencies) do
   local res=glb_resource_manager.resources[n]
   res.count-=v
  end
 end
end

function resource_cls:is_mouse_over()
 local x,y
 x,y=self:get_cur_xy()
 local dx=glb_mouse_x-x
 local dy=glb_mouse_y-y
 return dx>=0 and dx<=glb_resource_w and dy>=0 and dy<=glb_resource_w
end
