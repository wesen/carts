cls_tab=class(function(self, name)
 self.name=name
 self.button=cls_button.init(0,0,self.name)
 self.button.is_visible=function() return glb_current_tab==self end
 self.button.on_hover=function()
   glb_dialogbox.visible=true
   glb_dialogbox.text={{7,"switch to "..self.name.." tab"}}
 end
 self.button.on_click=function() glb_current_tab=self end
end)

function cls_tab:draw()
end

cls_money_tab=subclass(cls_tab,function(self,name)
 cls_tab._ctr(self,name)
end)

function cls_money_tab:draw()
 local x=25
 local y=20

 self.current_hire_worker=nil

 for i,k in pairs(glb_hire_workers) do
  local w=82
  local h=12
  local is_mouse_over=glb_mouse_x>=x and glb_mouse_x<=x+w and glb_mouse_y>=y and glb_mouse_y<=y+h
  bstr(tostr(#k.workers).."x",x-23,y-1,7,0)
  spr(k.spr,x-12,y-2)
  if k:is_visible() then
   if is_mouse_over then
    self.current_hire_worker=k
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
