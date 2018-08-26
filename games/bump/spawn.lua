spr_spawn_point=1

cls_spawn=subclass(typ_spawn,cls_actor,function(self,pos)
    cls_actor._ctr(self,pos)
    self.is_solid=false
    self.target=self.pos
    self.pos=v2(self.target.x,128)
    self.spd.y=-2
    add(room.spawn_points,self)
end)

function cls_spawn:update()
    self:move(self.spd)
    if self.pos.y<self.target.y then
        self.spd.y=0
        self.pos=self.target
        del(actors,self)
        cls_player.init(self.target)
        cls_smoke.init(self.pos,spr_full_smoke,0)
    end
end

function cls_spawn:draw()
    spr(spr_spawn_point,self.pos.x,self.pos.y)
end