function _init()
 room=cls_room.init(v2(1,0))
 room:spawn_player()
end

function _draw()
 frame+=1

 cls()
 room:draw()
 draw_actors()
 foreach(players,function(player)
  player:draw()
 end)
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs()
 foreach(players,function(player)
  player:update()
 end)
 update_actors()
end
