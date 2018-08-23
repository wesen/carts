-- main functions
function _init()
    init_object(player,1*8,12*8)
end

function _update()
    frames=((frames+1%30))
    if frames==0 then
        seconds=(seconds+1)%60
        if seconds==0 then
            minutes+=1
        end
    end

    if sfx_timer>0 then
        sfx_timer-=1
    end

    foreach(objects,function(obj)
        obj.move(obj.spd.x,obj.spd.y)
        if obj.type.update!=nil then
            obj.type.update(obj)
        end
    end)
end

function _draw()
    pal()

    -- clear screen
    local bg_col=0
    rectfill(0,0,128,128,bg_col)

    -- renders only layer 4 (only bg, used for title screen too)
    map(room.x*16,room.y*16,0,0,16,16,4)

    -- draw terrain
	local off=0
    map(room.x*16,room.y*16,off,0,16,16,2)

    -- draw objects
    foreach(objects, function(o)
        draw_object(o)
    end)

    -- draw fg terrain
    map(room.x*16,room.y*16,0,0,16,16,8)


end
