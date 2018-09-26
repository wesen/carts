function _init()
 glb_player=cls_player.init()
 glb_level=cls_level.init()
 glb_main_camera=cls_camera.init()
 glb_main_camera:set_target(glb_player)
 -- music(1)
end

function _draw()
 glb_frame+=1
 cls()

 local camx,camy
 camx,camy=glb_main_camera:compute_position()
 --
 camera(camx,camy)
 glb_level:draw()
 for _,actor in pairs(glb_actors) do actor:draw() end
 glb_player:draw()

end

function _update60()
 cls()
 glb_dt=time()-glb_lasttime
 glb_lasttime=time()
 tick_crs(glb_crs)
 glb_player:update()
 for _,actor in pairs(glb_actors) do actor:update() end
 --
 glb_main_camera:update()
end
