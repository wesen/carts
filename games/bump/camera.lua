local camera_shake=v2(0,0)

function add_shake(p)
 camera_shake+=angle2vec(rnd(1))*p
end

function update_shake()
 if abs(camera_shake.x)+abs(camera_shake.y)<1 then
  camera_shake=v2(0,0)
 end
 if frame%4==0 then
  camera_shake*=v2(-0.4-rnd(0.1),-0.4-rnd(0.1))
 end
end
