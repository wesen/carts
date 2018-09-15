function _init()
 room=cls_room.init(v2(0,16),v2(16,16))
 room:spawn_player(p1_input)
 room:spawn_player(p1_input)
 room:spawn_player(p1_input)
 room:spawn_player(p1_input)
 fireflies_init(v2(16,16))
 -- room:spawn_player(p2_input)
 --room:spawn_player(p3_input)
 --room:spawn_player(p4_input)
end

function _draw()
 frame+=1

 cls()
 camera(camera_shake.x,camera_shake.y)
 room:draw()
 for a in all(interactables) do
  a:draw()
 end
 for a in all(environments) do
  a:draw()
 end
 for a in all(static_objects) do
  a:draw()
 end
 draw_actors()
 tick_crs(draw_crs)
 fireflies_draw()

 for a in all(particles) do
  a:draw()
 end

 local entry_length=50
 for i=0,#scores-1,1 do
  print(
   "player "..tostr(i+1)..": "..tostr(scores[i+1]),
   i*entry_length,1,7
  )
 end

 -- print(tostr(stat(1)).." actors "..tostr(#actors),0,8,7)
 -- print(tostr(stat(1)/#particles).." particles "..tostr(#particles),0,16,7)
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 check_for_new_players()

 for a in all(actors) do
  a:update_bbox()
 end
 tick_crs()
 foreach(environments, function(a)
  a:update()
 end)
 update_actors()
 foreach(particles, function(a)
  a:update()
 end)
 foreach(interactables, function(a)
  a:update()
 end)
 update_shake()

 fireflies_update()
end
