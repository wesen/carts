function _init()
 poke(0x5f2d,1)
 if glb_debug then
  local coder=cls_coder.init(3)
  coder.t=1
  cls_coder.init(3)
  local gfx_artist=cls_gfx_artist.init(2)
  gfx_artist=cls_gfx_artist.init(3)
  local game_designer=cls_game_designer.init(2)
  game_designer=cls_game_designer.init(2)
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

function _draw()
 glb_frame+=1
 cls(glb_bg_col)
 glb_resource_manager:draw()
 spr(1,glb_mouse_x,glb_mouse_y)

 for _,v in pairs(glb_particles) do
  v:draw()
 end

 glb_dialogbox:draw()
end

function _update60()
 glb_dialogbox.visible=false
 glb_dt=time()-glb_lasttime

 local mouse_btn=stat(34)
 glb_mouse_left_down=band(glb_prev_mouse_btn,1)!=1 and band(mouse_btn,1)==1
 glb_mouse_right_down=band(glb_prev_mouse_btn,2)!=2 and band(mouse_btn,2)==2
 glb_prev_mouse_btn=mouse_btn

 glb_mouse_x=stat(32)
 glb_mouse_y=stat(33)
 glb_lasttime=time()
 glb_resource_manager:update()
 tick_crs(crs)

 for _,v in pairs(glb_particles) do
  v:update()
 end
end
