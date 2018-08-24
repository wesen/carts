actors={}

cls_actor=class(typ,function(self,pos)
    self.pos=pos
    self.spd=v2(0,0)
    self.rem=v2(0,0)
    self.hitbox=hitbox(v2(0,0),v2(8,8))
end)

function cls_actor:bbox(offset)
    if (offset==nil) offset=v2(0,0)
    return self.hitbox:to_bbox_at(self.pos+offset)
end

function cls_actor:move(o)
    self.pos+=o
end

function cls_actor:is_solid(offset)
    return solid_at(self:bbox(offset))
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
