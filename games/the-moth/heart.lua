cls_heart=subclass(typ_heart,cls_particle,function(self,pos)
 cls_particle._ctr(self,pos+v2(mrnd(3),-rnd(3)-2),2.5+rnd(2),{20})
 self.spd=v2(0,-rnd(0.3)-0.2)
 self.amp=0.6+rnd(0.4)
 self.offset=maybe() and 0 or 0.5
 self.angle_spd=rnd(.4)+0.3
 self.ghosts={}
end)

function cls_heart:update()
 self.spd.x=cos(self.t*self.angle_spd+self.offset)*self.amp
 cls_particle.update(self)

 if #self.ghosts<7 then
  if (frame%5==0) insert(self.ghosts,self.pos:clone())
 else
  popend(self.ghosts)
 end
end

function cls_heart:draw()
 cls_particle.draw(self)

 local cols={8,8,14,14,15,15,6,6,7}
 for i,ghost in pairs(self.ghosts) do
  circfill(ghost.x+4,ghost.y+4,.5,cols[i])
 end
end
