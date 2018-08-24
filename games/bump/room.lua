room={pos=v2(0,0)}

function room_draw()
    map(room.pos.x,room.pos.y,0,0)
end

function solid_at(bbox)
    return tile_flag_at(bbox,flg_solid)
end

function tile_at(x,y)
    return mget(room.pos.x*16+x,room.pos.y*16+y)
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