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
 spr(self.spr+frame(8,2),self.x,120,1,1,self.dir<0)
 -- spr(self.spr+frame(8,3),self.x,120,8,8,self.dir>0)
end

function cls_worker:on_tick()
 local res=self.default_resource
 local max_requirements={}
 for _,v in pairs(self.auto_resources) do
  for name,dep in pairs(v.dependencies) do
   if (max_requirements[name]~=nil) max_requirements[name]=dep
   max_requirements[name]=max(dep,max_requirements[name])
  end
 end


 for name,v in pairs(max_requirements) do
  printh(name.." "..tostr(v))
 end
 local potential_resources={}

 for _,v in pairs(self.auto_resources) do
  if v:are_dependencies_fulfilled() then
   local add_res=true
   printh("considering "..v.name)
   for name,dep in pairs(v.dependencies) do
    if glb_resource_manager.resources[name].count<max_requirements[name] then
     add_res=false
     printh("discarding "..v.name.." because of "..name)
    end
   end
   if (add_res) add(potential_resources,v)
  end
 end

 if #potential_resources>0 then
  res=rnd_elt(potential_resources)
  printh("potential_resources:")
  for _,v in pairs(potential_resources) do
   printh(v.name)
  end
 end
 printh("\n")

 if (res==nil) return

 res:produce()
 self.duration=res.duration
 local text=rnd_elt({"wow","ok","!!!","yeah","boom","kaching","lol","haha"})
 cls_score_particle.init(self.x-(#text/2),115,text,0,7)
end

cls_coder=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=64
 self.default_resource=res_loc
 self.auto_resources={res_func,res_csharp_file}
end)

cls_gfx_artist=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=80
 self.default_resource=res_pixel
 self.auto_resources={res_tilemap,res_sprite,res_animation}
end)

cls_game_designer=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=96
 self.auto_resources={res_prop,res_character,res_level}
end)
