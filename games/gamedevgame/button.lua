cls_button=class(function(self,x,y,text)
 self.x=x
 self.y=y
 self.text=text
 self.w=(#self.text)*4+1
 self.h=5
 self.is_visible=function() return false end
 self.on_click=function() end
 self.on_hover=function() end
 self.blink_on_hover=fakse
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
 local bg=self.is_visible() and glb_bg_col2 or 13
 local fg=self.is_visible() and 7 or 6

 if self:is_visible() and not self.blink_on_hover then
  draw_rounded_rect2(x,y,w,h,bg,bg,7)
 elseif self:is_mouse_over() then
  if frame(12,2)==0 then
   draw_rounded_rect2(x-1,y-1,w+2,h+2,bg,bg,7)
  else
   draw_rounded_rect2(x,y,w,h,bg,bg,7)
  end
 else
  draw_rounded_rect2(x,y,w,h,bg,bg,5)
 end

 if self:is_mouse_over() then
  self.on_hover()
  if (glb_mouse_left_down) self.on_click()
 end
 print(self.text,x+1,y,fg)
end
