cls_worker=class(function(self,duration)
 self.t=0
 self.orig_duration=duration/glb_timescale
 self.duration=self.orig_duration
 self.spr=64
 self.x=flr(rnd(120))
 self.spd_x=rnd(0.2)+0.2
 self.dir=1
 self.state=0 -- 0=walking, 1=jumping
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
 local text=rnd_elt({"wow","ok","!!!","yeah","boom","kaching","lol","haha"})
 cls_score_particle.init(self.x-(#text/2),115,text,0,7)
end

cls_coder=subclass(cls_worker,function(self,duration)
 cls_worker._ctr(self,duration)
 self.spr=64
end)

function cls_coder:on_tick()
 cls_worker.on_tick(self)
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
 self.spr=80
end)

function cls_gfx_artist:on_tick()
 cls_worker.on_tick(self)
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
