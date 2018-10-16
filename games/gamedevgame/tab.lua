cls_tab=class(function(self, name)
 self.name=name
end)

function cls_tab:draw()
end

cls_money_tab=subclass(cls_tab,function(self,name)
 cls_tab._ctr(self,name)
end)

function cls_money_tab:draw()
 local x=15
 local y=20
 for i,k in pairs(glb_hire_workers) do
  local w=82
  local h=12
  local is_mouse_over=glb_mouse_x>=x and glb_mouse_x<=x+w and glb_mouse_y>=y and glb_mouse_y<=y+h
  if k:is_visible() then
   if is_mouse_over then
    if frame(12,2)==0 then
     draw_rounded_rect2(x-1,y-1,w+2,5+2,13,13,7)
    else
     draw_rounded_rect2(x,y,w,5,13,13,7)
    end
    glb_dialogbox.visible=true
    glb_dialogbox.text={{7,"hire a "..k.name}}
    print(k.name,x+1,y,7)
    if (glb_mouse_left_down) k:hire()
   else
    draw_rounded_rect2(x,y,w,5,glb_bg_col2,glb_bg_col2,7)
    print(k.name,x+1,y,7)
   end
  else
    draw_rounded_rect2(x,y,w,5,13,13,5)
    print(k.name,x+1,y,6)
  end
  y+=h
 end
end

tab_game=cls_tab.init("gamedev")
tab_money=cls_money_tab.init("studio")
tab_release=cls_tab.init("release")

glb_resource_manager.tabs={tab_game,tab_release,tab_money}
glb_current_tab=tab_game
