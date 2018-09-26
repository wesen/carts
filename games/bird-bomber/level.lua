glb_level=nil

cls_level=class(function(self)
end)

function cls_level:draw()
 map(0,0,0,0,32,16)
end

function solid_at_offset(bbox,x,y)
 if (bbox.aay+y<0) return true
 return false
end
