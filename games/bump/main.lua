winning_player=nil

function _init()
 room=cls_room.init(v2(0,16),v2(16,16))
 room:spawn_player(p1_input)
 room:spawn_player(p2_input)
 -- room:spawn_player(p3_input)
 fireflies_init(v2(16,16))
 music(0)
end

function update_a(a) a:update() end
function draw_a(a) a:draw() end

function _draw()
 frame+=1

 cls()
 camera(camera_shake.x,camera_shake.y)
 room:draw()
 foreach(interactables, draw_a)
 foreach(environments, draw_a)
 foreach(static_objects, draw_a)
 draw_actors()

  tick_crs(draw_crs)

 if winning_player==nil then
  tick_crs(draw_crs)
  fireflies_draw()
  foreach(particles, draw_a)

  local entry_length=30
  for i=0,#scores-1,1 do
   print(
   "p"..tostr(i+1)..": "..tostr(scores[i+1]),
   i*entry_length,1,7
   )
  end
 end
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 check_for_new_players()

 for a in all(actors) do a:update_bbox() end
 tick_crs()
 foreach(environments, update_a)
 update_actors()
 foreach(particles, update_a)
 foreach(interactables, update_a)
 update_shake()

 fireflies_update()
end
