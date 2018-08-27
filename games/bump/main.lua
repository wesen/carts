function _init()
 room=cls_room.init(v2(16,0),v2(32,16))
 room:spawn_player()
end

function _draw()
 frame+=1

 cls()
 local player=players[1]
 if player!=nil then
  camera(flr(player.pos.x/128)*128,0)
 end

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
