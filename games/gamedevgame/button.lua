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
    draw_rounded_rect2(x-1,y-1,w+2,h+2,bg,bg,7)
   else
    draw_rounded_rect2(x,y,w,h,bg,bg,7)
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
