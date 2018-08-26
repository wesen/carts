function _init()
    load_room(v2(0,0))
    -- cls_player.init(v2(5,13)*8)
end

function _draw()
    frame+=1

    cls()
    room_draw()
    draw_actors()
    foreach(players,function(player)
        player:draw()
    end)
end

function _update60()
    dt=time()-lasttime
    lasttime=time()
    foreach(players,function(player)
        player:update()
    end)
    update_actors()
end
