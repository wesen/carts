glb_level=nil

cls_level=class(function(self)
 self.length=80
 self.environment={}
 self.background={}
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

-- cloud
cls_cloud=class(function(self,x,y,w,h)
 self.x=x
 self.y=y
 self.w=w
 self.h=h
end)

function cls_cloud:draw()
end
-- island

cls_island=class(function(self,length)
 self.tiles_top={}
 self.tiles={}
 for i=1,length do
  add(self.tiles,rnd_elt({102,103,104,105,106}))
  add(self.tiles_top,rnd_elt({86,87,88,89,90}))
 end
 self.aax=0
 self.aay=120
 self.bbx=length*8
 self.bby=128
end)

function cls_island:draw()
 for i=1,#self.tiles do
  spr(self.tiles_top[i],i*8,120-8)
 end
 palt(0,false)
 for i=1,#self.tiles do
  spr(self.tiles[i],i*8,120)
 end
 palt()
 -- rect(self.aax,self.aay,self.bbx,self.bby,8)
end
