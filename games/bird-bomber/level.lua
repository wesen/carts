glb_level=nil

cls_level=class(function(self)
 self.length=80
 self.environment={}
 add(self.environment,cls_island.init(self.length))
end)

function cls_level:draw()
 for _,env in pairs(self.environment) do
  env:draw()
 end
end

function solid_at_offset(bbox,x,y)
 if (bbox.aay+y>120 or
     bbox.aay+y<-64 or
     bbox.aax+x<0 or
     bbox.aax+x>glb_level.length*8) then
  return true
 end
 for _,env in pairs(glb_level.environment) do
  if (do_bboxes_collide_offset(bbox,env,x,y)) return true
 end
 return false
end
