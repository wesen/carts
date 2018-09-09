level=nil

cls_level=class(function(self)
end)

function cls_level:draw()
 map(0,0,0,0,32,16)
end

function cls_level:bbox()
 return bbox(v2(0,0),v2(256,128))
end

function cls_level:update()
end

function cls_level:solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>256
  or bbox.aa.y<0
  or bbox.bb.y>120 then
   return true,nil
 else
  for e in all(self.environment) do
   if (bbox:collide(e:bbox())) return true,e
  end
  return false
 end
end

function solid_at(bbox)
 return level:solid_at(bbox)
end
