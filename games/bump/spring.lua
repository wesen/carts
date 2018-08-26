spr_spring_sprung=66
spr_spring_wound=67
cls_spring=subclass(typ_spring,cls_actor,function(self,pos)
    cls_actor._ctr(self,pos)
    self.hitbox=hitbox(v2(0,5),v2(8,3))
    self.sprung_time=0
end)
tiles[tile_spring]=cls_spring

function cls_spring:update()
    -- collide with players
    local bbox=self:bbox()
    if self.sprung_time>0 then
        self.sprung_time-=1
    else
        for player in all(players) do
            if bbox:collide(player:bbox()) then
                player.spd.y=-3
                self.sprung_time=10
            end
        end
    end
end

function cls_spring:draw()
    -- self:bbox():draw(9)
    local spr_=spr_spring_wound
    if (self.sprung_time>0) spr_=spr_spring_sprung
    spr(spr_,self.pos.x,self.pos.y)
end