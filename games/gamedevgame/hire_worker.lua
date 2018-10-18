cls_hire_worker=class(function(self,name,cls,dependencies,spr,cost)
 self.cls=cls
 self.name=name
 self.workers={}
 self.dependencies=dependencies
 self.spr=spr
 self.cost=cost

 self.button=cls_button.init(0,0,self.name)
 local button=self.button
 button.blink_on_hover=true
 button.w=54
 button.h=5

 button.is_active=function() return self:is_hireable() end
 button.is_visible=function() return true end
 button.on_hover=function()
  tab_money.current_hire_worker=self
 end
 button.on_click=function()
  if (self:is_hireable()) self:hire()
 end
 button.should_blink=function()
  return button.is_active() and button:is_mouse_over()
 end

 self.dismiss_button=cls_button.init(0,0,"dismiss")
 local dismiss_button=self.dismiss_button
 dismiss_button.w=29
 dismiss_button.h=5

 dismiss_button.is_visible=function()
  return #self.workers>0
 end
 dismiss_button.is_active=dismiss_button.is_visible
 dismiss_button.should_blink=function() return dismiss_button:is_mouse_over() end
 dismiss_button.on_click=function()
  self:dismiss()
 end
end)

function cls_hire_worker:hire()
 local w=self.cls.init(2+rnd(2))
 glb_resource_manager.money-=self.cost
 add(self.workers,w)
 w.spr=self.spr
end

function cls_hire_worker:is_hireable()
 if (glb_resource_manager.money<self.cost) return false
 for k,v in pairs(self.dependencies) do
  local res=glb_resource_manager.resources[k]
  if (not res.created or res.count<v) return false
 end
 return true
end

function cls_hire_worker:dismiss()
 if #self.workers>0 then
  local worker=self.workers[1]
  del(self.workers,worker)
  del(glb_resource_manager.workers,worker)
 end
end

glb_hire_workers={
 cls_hire_worker.init("coder",cls_coder,{},spr_coder,5),
 cls_hire_worker.init("artist",cls_gfx_artist,{},spr_gfx_artist,20),
 cls_hire_worker.init("game designer",cls_game_designer,{},spr_game_designer,20),
 cls_hire_worker.init("tweeter",cls_tweeter,{release=0},spr_tweeter,10),
 cls_hire_worker.init("youtuber",cls_youtuber,{release=0},spr_youtuber,10),
 cls_hire_worker.init("twitcher",cls_twitcher,{release=0},spr_twitcher,10)
}
