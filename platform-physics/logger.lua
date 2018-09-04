cls_logger=class(function(self,duration)
 self.values={}
 self.duration=duration
end)

function cls_logger:add(key,val)
 if (self.values[key]==nil) self.values[key]={}
 local l=self.values[key]
 insert(l,val,128)
end

function cls_logger:draw(key,min,max,col)
 local l=self.values[key]
 local range=max-min
 if l!=nil then
  for i=#l,1,-1 do
   local v=l[i]
   local y=64+64*(v-min)/range
   pset(128-i,y,col)
  end
 end
end
