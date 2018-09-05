cls_clock=class(function(self,pos)
 self.t=0
 self.pos=pos
end)

function cls_clock:update()
 self.t+=dt
end

function cls_clock:draw()
 for i=0,10 do
  local x=cos(self.t-i*0.1)
  local y=sin(self.t-i*0.1)
  darken(i*10)
  circfill(self.pos.x+x*10,self.pos.y+y*10,(10-i)/3,7)
 end
 pal()
end
