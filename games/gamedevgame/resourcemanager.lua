resource_manager_cls=class(function(self)
 self.resources={}
end)

function resource_manager_cls:draw()
 for _,k in pairs(self.resources) do
  k:draw()
 end
end

function resource_manager_cls:update()
 if glb_mouse_left_down then
  for _,k in pairs(self.resources) do
   if (k:is_mouse_over()) k:on_click()
  end
 end

 for _,k in pairs(self.resources) do
  k:update()
 end
end

glb_resource_manager=resource_manager_cls.init()
