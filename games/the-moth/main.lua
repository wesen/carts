main_camera=cls_camera.init()

function _init()
 game:load_level(2)
end

function _draw()
 frame+=1

 cls()
 local p=main_camera:compute_position()
 camera(p.x,p.y)

 room:draw()
 draw_actors()
 if (player!=nil) player:draw()
 if (moth!=nil) moth:draw()

 palt(0,false)
 for a in all(actors) do
  if (a.draw_text!=nil) a:draw_text()
 end
 palt()
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs()
 if (player!=nil) player:update()
 if (moth!=nil) moth:update()
 update_actors()
 main_camera:update()
end
