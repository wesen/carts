winning_player=nil

mode_title=0
mode_game=1
mode_end=2

mode=mode_title

function start_game()
 room=cls_room.init(v2(0,16),v2(16,16))
 for i=1,4 do
  scores[i]=0
 end
end

function end_game()
  add_cr(function()
   for i=0,30 do
    palt(0,false)
    circfill(64,64,inexpo(i,0,80,30),8)
    palt()
    yield()
   end
   printh("mode end")
   mode=mode_end
  end, draw_crs)
end

function is_space_pressed()
 if stat(30) then
  printh(tostr(stat(31)))
 end
end

function _init()
 poke(0x5f2d,1)
 room=cls_room.init(v2(0,0),v2(16,16))
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
 if mode==mode_title then
  draw_title()
 end

 if mode!=mode_end then
  camera(camera_shake.x,camera_shake.y)
  room:draw()
  foreach(interactables, draw_a)
  foreach(environments, draw_a)
  foreach(static_objects, draw_a)
  draw_actors()

  tick_crs(draw_crs)
  fireflies_draw()
  foreach(particles, draw_a)

  if mode==mode_game then
   local entry_length=30
   for i=0,#scores-1,1 do
    print(
    "p"..tostr(i+1)..": "..tostr(scores[i+1]),
    i*entry_length,1,7
    )
   end
  end
 else
  rectfill(0,0,128,128,8)
  bstr("player "..tostr(winning_player).." won!",38,64,7,1)
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
