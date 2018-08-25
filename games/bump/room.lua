room={pos=v2(0,0)}

function load_room(pos)
    room.pos=pos
    for i=0,15 do
        for j=0,15 do
            local t=tiles[tile_at(i,j)]
            if t!=nil then
                t.init(v2(i,j))
            end
        end
    end
end

function room_draw()
    map(room.pos.x,room.pos.y,0,0)
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