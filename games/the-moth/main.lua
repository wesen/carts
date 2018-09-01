main_camera=cls_camera.init()

function _init()
 game:load_level(1,true)
end

local text_col=0

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
  sspr(66,2,43,11,21,21,86,22)
  local fidx=flr(frame/8)%3*8
  sspr(8+fidx,0,8,8,2,24,16,16)
  sspr(40+fidx,0,8,8,110,25,16,16)
  print("- slono -",48,46,15)

  local cols={6,6,13,13,5,5,1,1,5,5,13,13}
  print("guide bepo to the exit", 20, 58, cols[text_col+1])
  print("c - jump", 51, 66, cols[text_col+1])
  if (frame%4==0) text_col=(text_col+1)%#cols
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
