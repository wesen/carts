-- main functions
function _init()
    _player.type.init(_player)
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

    obj_move(_player,_player.spd.x,_player.spd.y)
    _player.type.update(_player)
end

function _draw()
    pal()

    -- clear screen
    local bg_col=0
    rectfill(0,0,128,128,bg_col)

    -- renders only layer 4 (only bg, used for title screen too)
    map(room.x*16,room.y*16,0,0,16,16,4)

    -- draw terrain (everything except -4)
	local off=-4
    map(room.x*16,room.y * 16,off,0,16,16,2)

    -- draw player
    _player.type.draw(_player)

end
