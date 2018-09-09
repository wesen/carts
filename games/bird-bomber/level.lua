level=nil

cls_level=class(function(self)
end)

function cls_level:draw()
 rect(0,0,127,127,7)
end

function cls_level:bbox()
 return bbox(v2(0,0),v2(128,128))
end

function cls_level:update()
end

function cls_level:solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>128
  or bbox.aa.y<0
  or bbox.bb.y>128 then
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
