cls_bubble=subclass(typ_bubble,cls_actor,function(self,pos,dir)
    cls_actor._ctr(self,pos)
    self.spd=v2(dir*rnd(0.5),rnd(0.2)-0.1)
    self.life=5+rnd(2)
    self.size=rnd(4)+2
end)

function cls_bubble:draw()
    circ(self.pos.x,self.pos.y,self.size,12)
end

function cls_bubble:update()
    self.life-=dt
    self:move(self.spd)
    if (self.life<0) del(actors,self)
end

function make_bubbles(pos,dir,n)
    for i=0,n do
        add(actors,cls_bubble.init(pos,dir))
    end
end