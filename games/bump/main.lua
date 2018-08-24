function _init()
end

function _draw()
    frame+=1

    cls()
    room_draw()
    draw_actors()
    player:draw()
end

function _update60()
    dt=time()-lasttime
    lasttime=time()
    player:update()
    update_actors()
end
