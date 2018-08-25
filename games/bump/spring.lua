cls_spring=subclass(typ_spring,cls_actor,function(self,pos)
    cls_actor._ctr(self,pos)
    self.spr=66
end)
tiles[tile_spring]=cls_spring

function cls_spring:update()
end
