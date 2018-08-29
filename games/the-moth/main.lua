main_camera=cls_camera.init()

function _init()
 fireflies_init()
 game:load_level(1)
end

function _draw()
 frame+=1

 cls()

 local p=main_camera:compute_position()

 -- camera(p.x/2,p.y/2)
 -- map(72,0,0,0,32,16)
 -- map(72,0,32,0,32,16)

 camera(p.x/1.5,p.y/1.5)
 map(72,32,0,0,32,16)
 map(72,32,32,0,32,16)

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

  fireflies_draw()
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs()
 fireflies_update()
 if (player!=nil) player:update()
 if (moth!=nil) moth:update()
 update_actors()
 main_camera:update()
end
