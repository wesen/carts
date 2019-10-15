glb_projectiles={}

cls_projectile=class(function(x,y,dx,dy)
 self.x=x
 self.y=y
 self.dx=dx
 self.dy=dy
 add(glb_projectiles,self)
 self.spr=16
end)

function cls_projectile:update()
 self.x+=self.dx
 self.y+=self.dy
end

function cls_projectile:draw()
 spr(self.spr,self.x+4,self.y+4)
end
