cls_worker=class(function(self,duration)
 self.t=0
 self.orig_duration=duration/glb_timescale
 self.duration=self.orig_duration
 self.spr=64
 self.x=flr(rnd(120))
 self.spd_x=rnd(0.2)+0.2
 self.dir=1
 self.state=0 -- 0=walking, 1=jumping
 self.auto_resources={}
 self.default_resource=nil
 self.tab=nil
 add(glb_resource_manager.workers,self)
end)

function cls_worker:update()
 self.t+=glb_dt
 if self.t>self.duration then
  self.duration=self.orig_duration
  self.t=0
  self:on_tick()
 end

 self.x+=self.dir*self.spd_x
 if (self.x<0 or self.x>120) self.dir*=-1
 if (maybe(1/200)) self.dir*=-1
end

function cls_worker:draw()
 if self:is_visible() then
  spr(self.spr+frame(8,2),self.x,120,1,1,self.dir<0)
  -- spr(self.spr+frame(8,3),self.x,120,8,8,self.dir>0)
 end
end

function cls_worker:is_visible()
 return self.tab==glb_current_tab
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
  res=rnd_elt(potential_resources)
 end

 if (res==nil) return

 res:produce()
 self.duration=max(self.orig_duration,res.duration)
 if self:is_visible() then
  local text=rnd_elt({"wow","ok","!!!","yeah","boom","kaching","lol","haha"})
  cls_score_particle.init(self.x-(#text/2),115,text,0,7)
 end
end

cls_coder=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=64
 self.default_resource=res_loc
 self.auto_resources={res_func,res_csharp_file,res_contract_work}
 self.tab=tab_game
end)

cls_gfx_artist=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=80
 self.default_resource=res_pixel
 self.auto_resources={res_tilemap,res_sprite,res_animation}
 self.tab=tab_game
end)

cls_game_designer=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=96
 self.auto_resources={res_prop,res_character,res_level}
 self.tab=tab_game
end)

cls_tweeter=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=96
 self.auto_resources={res_tweet}
 self.tab=tab_release
end)

cls_youtuber=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=64
 self.auto_resources={res_youtube}
 self.tab=tab_release
end)

cls_twitcher=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=80
 self.auto_resources={res_twitch}
 self.tab=tab_release
end)

cls_gamer=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=80
 self.auto_resources={}
 self.tab=tab_release
end)

cls_hire_worker=class(function(self,name,cls,dependencies)
 self.cls=cls
 self.name=name
 self.workers={}
 self.dependencies=dependencies or {}
end)

function cls_hire_worker:hire()
 self.cls.init(2+rnd(2))
end

function cls_hire_worker:is_visible()
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
 cls_hire_worker.init("coder",cls_coder),
 cls_hire_worker.init("artist",cls_gfx_artist),
 cls_hire_worker.init("game designer",cls_game_designer),
 cls_hire_worker.init("social media manager",cls_tweeter,{release=0}),
 cls_hire_worker.init("youtuber",cls_youtuber,{release=0}),
 cls_hire_worker.init("twitcher",cls_twitcher,{release=0})
}
