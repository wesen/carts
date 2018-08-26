cls_spring=subclass(typ_spring,cls_actor,function(self,pos)
    cls_actor._ctr(self,pos)
    self.spr=66
    self.hitbox=hitbox(v2(0,3),v2(8,5))
end)
tiles[tile_spring]=cls_spring

function cls_spring:update()
    -- printh("collide spring self "..self:str())
    -- local p=self:would_collide(typ_player)
    -- printh("collide player "..tostr(#p))
end
