cls_tab=class(function(self, name)
 self.name=name
 self.button=cls_button.init(0,0,self.name)
 local button=self.button
 button.is_visible=function() return true end
 button.is_active=function() return glb_current_tab==self end
 button.on_hover=function()
   if glb_current_tab!=self then
    glb_dialogbox.visible=true
    glb_dialogbox.text={{7,"switch to "..self.name.." tab"}}
   end
 end
 button.on_click=function()
  if (glb_current_tab!=self) transition_tab(self)
 end
 button.should_blink=function()
  return button:is_mouse_over() and not button.is_active()
 end
 self.is_visible=function() return true end
end)

function cls_tab:draw()
end

cls_money_tab=subclass(cls_tab,function(self,name)
 cls_tab._ctr(self,name)
end)

function cls_money_tab:draw()
 local x=40
 local y=20

 self.current_hire_worker=nil

 for i,k in pairs(glb_hire_workers) do
  bstr(tostr(#k.workers).."x",x-28,y-1,7,0)
  spr(k.spr,x-12,y-2)
  k.button.y=y
  k.button.x=x
  k.button:draw()
  -- k.dismiss_button.y=y
  -- k.dismiss_button.x=x+60
  -- k.dismiss_button:draw()
  y+=k.button.h+7
 end
end

tab_game=cls_tab.init("office")
tab_release=cls_tab.init("release")
tab_release.is_visible=function()
 return res_build.created
end
tab_money=cls_money_tab.init("studio")
tab_money.is_visible=function()
 return glb_resource_manager.money>0 or #glb_resource_manager.workers>0
end

glb_resource_manager.tabs={tab_game,tab_release,tab_money}

function transition_tab(tab)
 add_cr(function()
  local w=8
  local w2=w*2
  for i=1,w,w/16 do
   i=inoutexpo(i,0,w+1,w)
   for j=0,i do
    palt(0,false)
    for x=0,128/w2-1 do
     for y=0,128/w2-1 do
      -- rect(x*w2+j,y*w2+j,x*w2+w2-j,y*w2+w2-j,0)
      rect(x*w2+w-j,y*w2+w-j,x*w2+w+j,y*w2+w+j,0)
     end
    end
   end
   palt()
   yield()
  end
  cls(7)
  yield()
  glb_mode=1
  glb_current_tab=tab

 end,glb_draw_crs)
end
glb_current_tab=tab_game
