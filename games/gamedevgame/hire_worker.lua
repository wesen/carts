cls_hire_worker=class(function(self,name,cls,dependencies,spr,cost,auto_resources,salary)
 self.cls=cls
 self.name=name
 self.workers={}
 self.dependencies=dependencies
 self.spr=spr
 self.cost=cost
 self.salary=salary
 self.auto_resources=auto_resources

 self.button=cls_button.init(0,0,self.name)
 local button=self.button
 button.blink_on_hover=true
 button.w=54
 button.h=5

 button.is_active=function() return self:is_hireable() end
 button.is_visible=function() return true end
 button.on_hover=function()
  tab_money.current_hire_worker=self
  if button.is_active() then
   glb_dialogbox.visible=true
   glb_dialogbox.text=self:get_display_text()
  end
 end
 button.on_click=function()
  if self:is_hireable() then
   self:hire()
   glb_mouse.jiggle=true
   make_pwrup_explosion(glb_mouse_x,glb_mouse_y,true)
  end
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
  cls_score_particle.init(mid(glb_mouse_x+5,5,80),glb_mouse_y+8,
   "dismissed a "..self.name,0,7)
  self:dismiss()
 end
 dismiss_button.on_hover=function()
  glb_dialogbox.visible=true
  glb_dialogbox.text={{7,"dismiss "..self.name}}
 end
end)

function cls_hire_worker:hire()
 local w=self.cls.init(2+rnd(2))
 glb_resource_manager.money-=self.cost
 w.auto_resources=self.auto_resources
 w.cost=self.salary
 w.hire_worker=self
 add(self.workers,w)
 add(glb_resource_manager.workers,w)
 glb_dialogbox:shake(3)
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

function cls_hire_worker:dismiss(worker)
 if #self.workers>0 and worker==nil then
  worker=self.workers[1]
 end

 if worker!=nil then
  del(self.workers,worker)
  del(glb_resource_manager.workers,worker)
 end
end

function cls_hire_worker:get_display_text()
 local result={
  {7,"hire a "..self.name},
  {7,"cost: $"..tostr(self.cost)},
  {7,"salary: $"..tostr(self.salary)},
  {7,"produces:"}
 }

 for _,resource in pairs(self.auto_resources) do
  add(result,{7,"- "..resource.full_name})
 end

 return result
end

glb_hire_workers={
 cls_hire_worker.init(
  "coder",cls_coder,{},spr_coder,5,
  coder_auto_resources,
  coder_salary
 ),
  cls_hire_worker.init(
  "artist",cls_gfx_artist,{},spr_gfx_artist,10,
  gfx_artist_auto_resources,
  gfx_artist_salary
 ),
 cls_hire_worker.init(
  "game designer",cls_game_designer,{},spr_game_designer,10,
  game_designer_auto_resources,
  game_designer_salary
 ),
 cls_hire_worker.init(
  "tweeter",cls_tweeter,{build=0},spr_tweeter,10,
  tweeter_auto_resources,
  tweeter_salary
 ),
 cls_hire_worker.init(
  "youtuber",cls_youtuber,{build=0},spr_youtuber,10,
  youtuber_auto_resources,
  youtuber_salary
 ),
 cls_hire_worker.init(
  "twitcher",cls_twitcher,{build=0},spr_twitcher,10,
  twitcher_auto_resources,
  twitcher_salary
 )
}

glb_hire_gamer=cls_hire_worker.init(
 "gamer",cls_gamer,{},spr_gamer,0,
 gamer_auto_resources,
 0
)
