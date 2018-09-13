spr_vanishing_platform=96

cls_vanishing_platform=class(function(self,pos)
 printh("Create vanishing platform")
 self.x=pos.x
 self.y=pos.y
 self.aax=pos.x
 self.aay=pos.y+0.5
 self.bbx=self.aax+8
 self.bby=self.aay+3.5
 add(environments,self)
end)
tiles[spr_vanishing_platform]=cls_vanishing_platform

function cls_vanishing_platform:collides_with(o,x,y)
 return do_bboxes_collide_offset(o,self,x,y)
end

function cls_vanishing_platform:draw()
 spr(spr_vanishing_platform,self.x,self.y)
end

function cls_vanishing_platform:update()
end
