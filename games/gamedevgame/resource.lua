resource_cls=class(function(self,name,x,y,dependencies,duration)
 self.x=x
 self.y=y
 self.name=name
 self.dependencies=dependencies
 self.duration=duration
 self.t=0
 self.count=0
 self.active=false
 self.created=false
 glb_resource_manager.resources[name]=self
end)

glb_resource_w=16

function resource_cls:draw()
 if (not self:is_visible()) return
 local col=7
 if (not self:are_dependencies_fulfilled()) col=5
 local x,y
 x,y=self:get_cur_xy()
 rect(x,y,x+glb_resource_w,y+glb_resource_w,col)
 print(tostr(self.count),x+2,y+glb_resource_w+2,col)
 if (self:is_mouse_over()) print(self.name,32,80,col)
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
 self.count+=1
 self.created=true
end

function resource_cls:is_mouse_over()
 local x,y
 x,y=self:get_cur_xy()
 local dx=glb_mouse_x-x
 local dy=glb_mouse_y-y
 return dx>=0 and dx<=glb_resource_w and dy>=0 and dy<=glb_resource_w
end
