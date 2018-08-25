spr_ground_smoke=51
spr_full_smoke=48

cls_smoke=subclass(typ_smoke,cls_actor,function(self,pos,start_spr,dir)
    cls_actor._ctr(self,pos+v2(mrnd(1),0))
    self.flip=v2(maybe(),false)
    self.spr=start_spr
    self.start_spr=start_spr
    self.is_solid=false
    self.spd=v2(dir*(0.3+rnd(0.2)),-0.0)
end)

function cls_smoke:update()
    self:move(self.spd)
    self.spr+=0.2
    if (self.spr>self.start_spr+3) del(actors,self)
end

function cls_smoke:draw()
    spr(self.spr,self.pos.x,self.pos.y)
end

function make_smoke(pos)
    add(actors,cls_smoke.init(pos))
end