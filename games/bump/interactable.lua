cls_interactable=class(function(self,x,y,hitbox_x,hitbox_y,hitbox_dim_x,hitbox_dim_y)
 add(interactables,self)
 self.x=x
 self.y=y
 self.aax=self.x+hitbox_x
 self.aay=self.y+hitbox_y
 self.bbx=self.aax+hitbox_dim_x
 self.bby=self.aay+hitbox_dim_y
end)

function cls_interactable:update()
end

function cls_interactable:draw()
 spr(self.spr,self.x,self.y)
end
