function _init()
end

function _draw()
    frame+=1

    cls()
    draw_actors()
end

function _update60()
    dt=time()-lasttime
    lasttime=time()
    update_actors()
end
