glb_dt=0
glb_lasttime=time()
glb_frame=0

glb_mouse_x=0
glb_mouse_y=0

glb_prev_mouse_btn=0
glb_right_button=false

glb_p1=cls_player.init()

function _init()
 poke(0x5f2d, 1)
end

function _update60()
 local _time=time()
 glb_dt=_time-glb_lasttime
 glb_lasttime=_time

 glb_mouse_x=stat(32)
 glb_mouse_y=stat(33)
 local _mouse_btn=stat(34)
 glb_right_button=band(_mouse_btn,1)==1 and not band(glb_prev_mouse_btn,1)==0
 glb_right_button_dwn=band(_mouse_btn,1)==1
 glb_left_button=band(_mouse_btn,2)==1 and not band(glb_prev_mouse_btn,2)==0
 glb_prev_mouse_btn=_mouse_btn

 glb_p1:update()

 for _,p in pairs(glb_projectiles) do
  p:update()
 end
end

function _draw()
 cls(1)
 glb_frame+=1

 glb_p1:draw()

 for _,p in pairs(glb_projectiles) do
  p:draw()
 end
end
