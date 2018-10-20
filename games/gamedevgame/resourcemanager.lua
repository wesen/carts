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
 local i=1
 for j=#self.workers,0,-1 do
  local k=self.workers[j]
  k:draw()
  i+=1
  if (i>30) break
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
