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
  bstr(tostr(#k.workers).."x",x-23,y-1,7,0)
  spr(k.spr,x-12,y-2)
  k.button.y=y
  k.button.x=x
  k.button:draw()
  y+=k.button.h+7
 end
end

tab_game=cls_tab.init("gamedev")
tab_money=cls_money_tab.init("studio")
tab_release=cls_tab.init("release")

glb_resource_manager.tabs={tab_game,tab_release,tab_money}
glb_current_tab=tab_game
