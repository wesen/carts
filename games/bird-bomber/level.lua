room=nil

cls_room=class(function(self)
end)

function cls_room:draw()
end

function cls_room:update()
end

function cls_room:solid_at(bbox)
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
 return room:solid_at(bbox)
end
