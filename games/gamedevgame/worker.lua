glb_workers={}

cls_worker=class(function(self,duration)
 self.t=0
 self.orig_duration=duration/glb_timescale
 self.duration=self.orig_duration
 add(glb_resource_manager.workers,self)
end)

function cls_worker:update()
 self.t+=glb_dt
 if self.t>self.duration then
  self.duration=self.orig_duration
  self.t=0
  self:on_tick()
 end
end

function cls_worker:on_tick()
end

cls_coder=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
end)

function cls_coder:on_tick()
 local auto_resources={res_build,res_csharp_file,res_func}
 for _,v in pairs(auto_resources) do
  if v:are_dependencies_fulfilled() then
   v:produce()
   self.duration=v.duration
   return
  end
 end
 res_loc.count+=1
end

cls_gfx_artist=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
end)

function cls_gfx_artist:on_tick()
 local auto_resources={res_sprite,res_animation}
 for _,v in pairs(auto_resources) do
  if v:are_dependencies_fulfilled() then
   v:produce()
   self.duration=v.duration
   return
  end
 end
 res_pixel.count+=1
end
