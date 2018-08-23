actors={}

cls_actor=class(typ,function(self,pos)
    self.pos=pos
end)

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
