function _init()
 player=cls_player.init()
 room=cls_room.init()
end

function _draw()
 frame+=1
 cls()
 for actor in all(actors) do
  actor:draw()
 end
 player:draw()

end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
 player:update()
 for actor in all(actors) do
  actor:update()
 end
end
