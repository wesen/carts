glb_mode=0

function _init()
 poke(0x5f2d,1)
 if glb_debug then
  res_loc.count=1000
  glb_timescale=1
  glb_resource_manager.money=10000
  res_csharp_file.count=1000
  res_csharp_file.created=true
  res_level.count=50
  res_level.created=true
  res_build.created=true
  res_build.count=5
  res_playtest.count=200
  res_playtest.created=true
  res_youtube.created=true
  res_twitch.created=true
  res_tweet.created=true
  res_youtube.count=5
  res_twitch.count=5
  res_tweet.count=5

  -- for i=1,80 do
  --  for _,v in pairs(glb_hire_workers) do
  --   v:hire()
  --  end
  -- end
 else
  glb_resource_manager.money=0
 end
end

glb_lasttime=time()
glb_dt=0
glb_frame=0

glb_mouse_x=0
glb_mouse_y=0
glb_prev_mouse_btn=0
glb_mouse_left_down=false
glb_mouse_right_down=false

glb_bg_col=1
glb_bg_col2=12

function set_mouse()
 local mouse_btn=stat(34)
 glb_mouse_left_down=band(glb_prev_mouse_btn,1)!=1 and band(mouse_btn,1)==1
 glb_mouse_right_down=band(glb_prev_mouse_btn,2)!=2 and band(mouse_btn,2)==2
 glb_prev_mouse_btn=mouse_btn

 glb_mouse_x=stat(32)
 glb_mouse_y=stat(33)
end

function tutorial_draw()
 glb_mouse:draw()
end

function _draw()
 set_mouse()
 glb_frame+=1
 cls(0)

 if true then
  tutorial_draw()
  return
 end

 for _,v in pairs(glb_pwrup_particles) do
  v:draw()
 end

 if glb_mode==1 then
  glb_resource_manager:draw()
 else
  title_draw()
 end
 glb_mouse:draw()

 for _,v in pairs(glb_particles) do
  v:draw()
 end

 if glb_mode==1 then
  glb_dialogbox:draw()
 end

 tick_crs(glb_draw_crs)
end

function _update60()
 glb_dialogbox.visible=false
 glb_dt=time()-glb_lasttime

 glb_lasttime=time()
 if glb_mode==1 then
  glb_resource_manager:update()
 else
  title_update()
 end

 tick_crs(glb_crs)

 for _,v in pairs(glb_pwrup_particles) do
  v:update()
 end

 for _,v in pairs(glb_particles) do
  v:update()
 end
end
