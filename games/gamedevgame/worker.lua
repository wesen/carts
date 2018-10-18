cls_worker=class(function(self,duration)
 self.t=0
 self.orig_duration=duration/glb_timescale
 self.duration=self.orig_duration
 self.spr=64
 self.y=120
 self.spd_y=0
 self.x=flr(rnd(120))
 self.spd_x=rnd(0.2)+0.2
 self.dir=1
 self.state=0 -- 0=walking, 1=jumping
 self.auto_resources={}
 self.default_resource=nil
 self.tab=nil
 self.cost=0
 self.hire_worker=nil
 self.no_salary_t=0
end)

function cls_worker:update()
 self.t+=glb_dt

 if (self.no_salary_t>0) self.no_salary_t+=glb_dt

 if self.t>self.duration then
  self.duration=self.orig_duration
  self.t=0
  if glb_resource_manager.money>=self.cost or self.hire_worker.name=="coder" then
   self:on_tick()
   self.no_salary_t=0
   glb_resource_manager.money-=self.cost
  else
   if (self.no_salary_t==0) self.no_salary_t=glb_dt

   if self.no_salary_t>10 and maybe(0.1) then
    self.hire_worker:dismiss(self)
    self:show_text("i quit!!",8,7)
    cls_score_particle.init(mid(24+5,5,80),64+8,
     "a "..self.hire_worker.name.." left",0,7)
   else
    self:show_text("$$$!",8,7)
   end
  end
 end

 self.x+=self.dir*self.spd_x
 self.y+=self.spd_y
 if self.y>120 then
  self.y=120
  self.spd_y=0
 end
 if self.spd_y!=0 then
  self.spd_y+=0.18
 end
 if (self.x<0 or self.x>120) self.dir*=-1
 if (maybe(1/200)) self.dir*=-1
end

function cls_worker:draw()
 if self:is_visible() then
  spr(self.spr+frame(8,2),self.x,self.y,1,1,self.dir<0)
  -- spr(self.spr+frame(8,3),self.x,120,8,8,self.dir>0)
 end
end

function cls_worker:is_visible()
 if glb_current_tab==tab_money then
  if tab_money.current_hire_worker!=nil then
   return getmetatable(self)==tab_money.current_hire_worker.cls
  else
   return true
  end
 else
  return self.tab==glb_current_tab
 end
end

function cls_worker:on_tick()
 local res=self.default_resource
 local max_requirements={}
 for _,v in pairs(self.auto_resources) do
  if v:are_dependencies_created() then
   for name,dep in pairs(v.dependencies) do
    if (max_requirements[name]~=nil) max_requirements[name]=dep
    max_requirements[name]=max(dep,max_requirements[name])
   end
  end
 end

 local potential_resources={}

 for _,v in pairs(self.auto_resources) do
  if v:are_dependencies_fulfilled() then
   local add_res=true
   for name,dep in pairs(v.dependencies) do
    if max_requirements[name]!=nil and glb_resource_manager.resources[name].count<max_requirements[name] then
     add_res=false
    end
   end
   if (add_res) add(potential_resources,v)
  end
 end


 if #potential_resources>0 and maybe(0.2) then
  local min_count=1000
  for _,k in pairs(potential_resources) do
   if k.count<min_count then
    res=k
    min_count=k.count
   elseif k.name=="contract" and maybe(0.3) then
    res=k
    break
   end
  end
 end

 if (res==nil) return

 res:produce()
 self.spd_y=-1.5+mrnd(0.75)
 
 self.duration=max(self.orig_duration,res.duration)
 if self:is_visible() then
  local text=rnd_elt({"wow","ok","!!!","yeah","boom","kaching","lol","haha"})
  self:show_text(text,0,7)
 end
end

function cls_worker:show_text(text,fg,bg)
  cls_score_particle.init(self.x-(#text/2),self.y-5,text,fg,bg)
end

spr_coder=64
coder_auto_resources={res_func,res_csharp_file,res_contract_work}
coder_salary=0.05
cls_coder=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.default_resource=res_loc
 self.tab=tab_game
 self.duration/=2
end)

spr_gfx_artist=80
gfx_artist_salary=0.05
gfx_artist_auto_resources={res_tilemap,res_sprite,res_animation}
cls_gfx_artist=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.default_resource=res_pixel
 self.tab=tab_game
end)

spr_game_designer=96
game_designer_auto_resources={res_prop,res_character,res_level}
game_designer_salary=0.1
cls_game_designer=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.tab=tab_game
end)

spr_tweeter=96
tweeter_salary=0.1
tweeter_auto_resources={res_tweet}
cls_tweeter=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.tab=tab_release
end)

spr_youtuber=64
youtuber_salary=0.1
youtuber_auto_resources={res_youtube}
cls_youtuber=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.tab=tab_release
end)

spr_twitcher=80
twitcher_salary=0.2
twitcher_auto_resources={res_twitch}
cls_twitcher=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.tab=tab_release
end)

spr_gamer=80
gamer_auto_resources={res_playtest}
cls_gamer=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.auto_resources={}
 self.spr=spr_gamer
 self.tab=tab_release
end)

function cls_gamer:is_visible()
 return glb_current_tab!=tab_money
end

function cls_gamer:on_tick()
 cls_worker.on_tick(self)
 local money=1+(res_release.count-1)*0.5
 glb_resource_manager.money+=money
 if (self:is_visible()) make_score_particle_explosion("$",flr(money)+1,self.x,116,11,3,5,2)
end
