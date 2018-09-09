cls_tether=class(function(self,pos)
  self.pos=pos
  add(tethers,self)
end)

function cls_tether:draw()
 circ(self.pos.x,self.pos.y,2,9)
end

function cls_tether:update()
end
