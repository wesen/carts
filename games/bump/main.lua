winning_player=nil

mode_title=0
mode_game=1
mode_end=2
mode_transition=3

mode=mode_game

function make_transition(mid_cb,end_cb)
 add_cr(function()
  local col=7
  local duration=15
  for i=0,duration do
   palt(col,false)
   local radius=inexpo(i,0,128,duration)
   circfill(64,64,radius,col)
   palt()
   yield()
  end
  if (mid_cb!=nil) mid_cb()
  for i=0,duration do
   palt(col,false)
   local radius=128-inexpo(i,0,128,duration)
   circfill(64,64,radius,col)
   palt()
   yield()
  end
 if (end_cb!=nil) end_cb()
 end, draw_crs)
end

function start_game()
 -- this is a pretty inelegant way of resetting global state
 interactables={}
 actors={}
 players={}
 particles={}
 fireflies_init(v2(16,16))
 crs={}
 pwrup_counts=0
 for i=1,4 do
  scores[i]=0
 end
 make_transition(function()
  mode=mode_transition
  room=cls_room.init(v2(0,16),v2(16,16))
 end, function()
  mode=mode_game
  for input,v in pairs(connected_players) do
   if v==true then
    room:spawn_player(input)
   end
  end
 end)
end

function end_game()
 make_transition(nil,function()
  mode=mode_end
 end)
end

function is_space_pressed()
 return stat(30) and stat(31)==" "
end

function _init()
 poke(0x5f2d,1)
 room=cls_room.init(v2(0,16),v2(16,16))
 room:spawn_player(p1_input)
 room:spawn_player(p2_input)
 -- room:spawn_player(p3_input)
 -- room:spawn_player(p4_input)
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
  if is_space_pressed() then
   start_game()
  end
 end

 if mode==mode_transition then
   tick_crs(draw_crs)
 else
  if mode!=mode_end then
   camera(camera_shake.x,camera_shake.y)
   room:draw()
   foreach(interactables, draw_a)
   foreach(environments, draw_a)
   foreach(static_objects, draw_a)
   draw_actors()

   fireflies_draw()
   foreach(particles, draw_a)
   tick_crs(draw_crs)

   if mode==mode_game then
    local entry_length=30
    palt(0,false)
    rectfill(0,120,128,128,0)
    for i=0,#scores-1,1 do
     print(
     "p"..tostr(i+1)..": "..tostr(scores[i+1]),
     i*entry_length+10,121,7
     )
    end
    palt()
   end
  else
   draw_title("player "..tostr(winning_player).." won!")
   local _spr=start_sprites[winning_player]+flr(frame/8)%3
   local sx=_spr%16*8
   local sy=flr(_spr/16)*8
   sspr(sx,sy,8,8,64-16,title_dy+56,32,32)

   if is_space_pressed() then
    run()
   end
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
