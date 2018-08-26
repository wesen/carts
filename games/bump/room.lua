cls_room=class(typ_room,function(self,pos)
    self.pos=pos
    self.spawn_points={}

    for i=0,15 do
        for j=0,15 do
            local p=v2(i,j)
            local tile=self:tile_at(p)
            if tile==spr_spawn_point then
                printh("Added spawn point at "..p:str())
                add(self.spawn_points,p*8)
            end
            local t=tiles[tile]
            if (t!=nil) t.init(p*8)
        end
    end
end)

function cls_room:draw()
    map(self.pos.x*16,self.pos.y*16,0,0,16,16,flg_solid+1)
end

function cls_room:spawn_player()
    printh("spawn point "..self.spawn_points[1]:str())
    cls_spawn.init(self.spawn_points[1]:clone())
end

function cls_room:tile_at(pos)
    local v=self.pos*16+pos
    return mget(v.x,v.y)
end

function solid_at(bbox)
    return bbox.aa.x<0
        or bbox.bb.x>128
        or bbox.aa.y<0
        or bbox.bb.y>128
        or tile_flag_at(bbox,flg_solid)
end

function ice_at(bbox)
    return tile_flag_at(bbox,flg_ice)
end

function tile_at(x,y)
    return room:tile_at(v2(x,y))
end

function tile_flag_at(bbox,flag)
    local x0=max(0,flr(bbox.aa.x/8))
    local x1=min(15,(bbox.bb.x-1)/8)
    local y0=max(0,flr(bbox.aa.y/8))
    local y1=min(15,(bbox.bb.y-1)/8)
    for i=x0,x1 do
        for j=y0,y1 do
            if fget(tile_at(i,j),flag) then
                return true
            end
        end
    end
    return false
end