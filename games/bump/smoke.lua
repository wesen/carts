cls_smoke=subclass(typ_smoke,cls_actor,function(self,pos,dir)
    cls_actor._ctr(self,pos+v2(mrnd(1),0))
    self.flip=v2(maybe(),false)
    self.spr=51
    self.spd=v2(dir*(0.3+rnd(0.2)),-0.0)
end)

function cls_smoke:update()
    self:move(self.spd)
    self.spr+=0.2
    if (self.spr>51+3) del(actors,self)
end

function cls_smoke:draw()
    spr(self.spr,self.pos.x,self.pos.y)
end

function make_smoke(pos)
    add(actors,cls_smoke.init(pos))
end