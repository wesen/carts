cls_camera=class(function(self)
 self.target=nil
 self.pull=16
 self.x=0
 self.y=0
 self.shkx=0
 self.shky=0
end)

function cls_camera:set_target(target)
 self.target=target
 self.x=target.x
 self.y=target.y
end

function cls_camera:compute_position()
 return self.x-64+self.shkx,self.y-64+self.shky
end

function cls_camera:abs_position(x,y)
 local posx,posy
 return x+self.x-64+self.shkx,y-64+self.shky+y
end

function cls_camera:pull_bbox()
 local v=v2(self.pull,self.pull)
 return {aax=self.x-self.pull,bbx=self.x+self.pull,aay=self.y-self.pull,bby=self.y+self.pull}
end

function cls_camera:update()
 if (self.target==nil) return
 local b=self:pull_bbox()
 local p=self.target
 if (b.bbx<p.x) self.x+=min(self.target.x-b.bbx,4)
 if (b.aax>p.x) self.x-=min(b.aax-p.x,4)
 if (b.bby<p.y) self.y+=min(p.y-b.bby,4)
 if (b.aay>p.y) self.y-=min(b.aay-p.y,4)
 self.x=mid(64,self.x,glb_level.length*8-64)
 self.y=mid(-64+64,self.y,128-64)
 self:update_shake()
end

-- from trasevol_dog
function cls_camera:add_shake(p)
 local a=rnd(1)
 self.shkx+=p*cos(a)
 self.shky+=p*sin(a)
end

function cls_camera:update_shake()
 if abs(self.shkx)+abs(self.shky)<1 then
  self.shkx=0
  self.shky=0
 end
 if glb_frame%4==0 then
  self.shkx*=-0.4-rnd(0.1)
  self.shky*=-0.4-rnd(0.1)
 end
end
