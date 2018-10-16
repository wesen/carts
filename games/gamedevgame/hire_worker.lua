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
 if (glb_resource_manager.money<=0) return false
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
