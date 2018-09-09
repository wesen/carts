cls_camera=class(function(self)
 self.target=nil
 self.pull=16
 self.pos=v2(0,0)
 self.shk=v2(0,0)
 -- this is where to add shake
end)

function cls_camera:set_target(target)
 self.target=target
 self.pos=target.pos:clone()
end

function cls_camera:compute_position()
 return v2(self.pos.x-64+self.shk.x,self.pos.y-64+self.shk.y)
end

function cls_camera:abs_position(p)
 return p+self:compute_position()
end

function cls_camera:pull_bbox()
 local v=v2(self.pull,self.pull)
 return bbox(self.pos-v,self.pos+v)
end

function cls_camera:update()
 if (self.target==nil) return
 local b=self:pull_bbox()
 local p=self.target.pos
 if (b.bb.x<p.x) self.pos.x+=min(p.x-b.bb.x,4)
 if (b.aa.x>p.x) self.pos.x-=min(b.aa.x-p.x,4)
 if (b.bb.y<p.y) self.pos.y+=min(p.y-b.bb.y,4)
 if (b.aa.y>p.y) self.pos.y-=min(b.aa.y-p.y,4)
 self.pos=room:bbox():shrink(64):clip(self.pos)
 self:update_shake()
end

-- from trasevol_dog
function cls_camera:add_shake(p)
 local a=rnd(1)
 self.shk+=v2(p*cos(a),p*sin(a))
end

function cls_camera:update_shake()
 if abs(self.shk.x)+abs(self.shk.y)<1 then
  self.shk=v2(0,0)
 end
 if frame%4==0 then
  self.shk*=v2(-0.4-rnd(0.1),-0.4-rnd(0.1))
 end
end
