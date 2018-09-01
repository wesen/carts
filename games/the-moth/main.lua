main_camera=cls_camera.init()

function _init()
 game:load_level(8,true)
end

function _draw()
 frame+=1

 cls()
 if not is_screen_dark then
  local p=main_camera:compute_position()
  camera(p.x/1.5,p.y/1.5)
  fireflies_draw()

  camera(p.x,p.y)
  if (room!=nil) room:draw()
  draw_actors()
  if (player!=nil) player:draw()
  if (moth!=nil) moth:draw()

  palt(0,false)
  for a in all(actors) do
   if (a.draw_text!=nil) a:draw_text()
  end
  palt()

  camera(0,0)
  -- print cpu
  -- print(tostr(stat(1)),64,64,1)
  -- print(tostr(stat(7)).." fps",64,70,1)
 end

 tick_crs(draw_crs)

 if game.current_level==1 then
  print("guide bepo to the exit", 20, 56, 7)
  print("c - jump", 40, 64, 7)
 end

end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
 fireflies_update()
 if (player!=nil) player:update()
 if (moth!=nil) moth:update()
 update_actors()
 main_camera:update()
end
