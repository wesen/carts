actors={}

cls_actor=class(typ,function(self,pos)
    self.pos=pos
    self.spd=v2(0,0)
    self.rem=v2(0,0)
end)

function cls_actor:move(o)
    self.pos+=o
end

function draw_actors(typ)
    for a in all(actors) do
        if ((typ==nil or a.typ==typ) and a.draw!=nil) a:draw()
    end
end

function update_actors(typ)
    for a in all(actors) do
        if ((typ==nil or a.typ==typ) and a.update!=nil) a:update()
    end
end
