function _init()
 player=cls_player.init()
 level=cls_level.init()
 main_camera=cls_camera.init()
 main_camera:set_target(player)
 music(1)
end

function _draw()
 frame+=1
 cls()

 local p=main_camera:compute_position()

 camera(p.x,p.y)
 level:draw()
 for actor in all(actors) do
  actor:draw()
 end
 player:draw()

end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
 player:update()
 for actor in all(actors) do
  actor:update()
 end

 main_camera:update()
end
