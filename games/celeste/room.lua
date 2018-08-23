function level_index()
    return room.x%8+room.y*8
end

function is_title()
    return level_index()==31
end

function load_room(x,y)
    foreach(objects,destroy_object)

    room.x=x
    room.y=y

    for tx=0,15 do
        for ty=0,15 do
            local tile=mget(room.x*16+tx,room.y*16+ty)
            foreach(types,function(type)
                if type.tile==tile then
                    init_object(type,tx*8,ty*8)
                end
            end)
        end
    end

    if not is_title() then
        init_object(room_title,0,0)
    end
end