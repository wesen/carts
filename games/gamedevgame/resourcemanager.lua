resource_manager_cls=class(function(self)
 self.workers={}
 self.resources={}
 self.tabs={}
 printh("tabs "..tostr(#self.tabs))
 self.money=0
end)

function resource_manager_cls:draw()
 local x=5
 local y=3

 for i,k in pairs(self.tabs) do
  local w=(#k.name)*4+1
  local is_visible=glb_current_tab==k
  local is_mouse_over=glb_mouse_x>=x and glb_mouse_x<=x+w and glb_mouse_y>=y and glb_mouse_y<=y+5
  if is_visible then
   draw_rounded_rect2(x,y,w,5,glb_bg_col2,glb_bg_col2,7)
   print(k.name,x+1,y,7)
   k:draw()
  elseif is_mouse_over then
   if frame(12,2)==0 then
    draw_rounded_rect2(x-1,y-1,w+2,5+2,13,13,7)
   else
    draw_rounded_rect2(x,y,w,5,13,13,7)
   end
   glb_dialogbox.visible=true
   glb_dialogbox.text={{7,"switch to "..k.name.." tab"}}
   print(k.name,x+1,y,7)

   if (glb_mouse_left_down) glb_current_tab=k
  else
   draw_rounded_rect2(x,y,w,5,13,13,5)
   print(k.name,x+1,y,6)
  end
  x+=w+5
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
  for _,k in pairs(self.resources) do
   if (k:is_mouse_over() and k:is_visible()) k:on_click()
  end
 end

 for _,k in pairs(self.resources) do
  k:update()
 end
 for _,k in pairs(self.workers) do
  k:update()
 end
end

glb_resource_manager=resource_manager_cls.init()
