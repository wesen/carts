function _init()
 player=cls_player.init()
end

function _draw()
 frame+=1
 cls()
 player:draw()

end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
 player:update()
end
