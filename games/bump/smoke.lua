cls_smoke=subclass(typ_smoke,cls_actor,function(self,pos)
    cls_actor._ctr(self,pos+v2(-1+rnd(2),-1+rnd(2)))
    self.flip=v2(maybe(),maybe())
    self.spr=48
    self.spd=v2(0.3+rnd(0.2),-0.0)
end)

function cls_smoke:update()
    self:move(self.spd)
    self.spr+=0.2
    if (self.spr>48+3) del(actors,self)
end

function cls_smoke:draw()
    spr(self.spr,self.pos.x,self.pos.y)
end

function make_smoke(pos)
    add(actors,cls_smoke.init(pos))
end