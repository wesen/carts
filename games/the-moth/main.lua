main_camera=cls_camera.init()

function _init()
 room=cls_room.init(v2(16,0),v2(32,16))
 room:spawn_player()
end

function _draw()
 frame+=1

 cls()
 local p=main_camera:compute_position()
 camera(p.x,p.y)

 room:draw()
 draw_actors()
 if (player!=nil) player:draw()
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs()
 if (player!=nil) player:update()
 update_actors()
 main_camera:update()
end
