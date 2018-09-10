function _init()
 room=cls_room.init(v2(16,0),v2(16,16))
 room:spawn_player(p1_input)
 room:spawn_player(p2_input)
end

function _draw()
 frame+=1

 cls()
 -- if player!=nil then
 --  camera(flr(player.pos.x/128)*128,0)
 -- end

 room:draw()
 draw_actors()
 tick_crs(draw_crs)

 local entry_length=50
 for i=0,#scores-1,1 do
  print(
   "player "..tostr(i+1)..": "..tostr(scores[i+1]),
   i*entry_length,1,7
  )
 end
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs()
 update_actors()
end
