
function draw_game()
  cls(0)
  map()
  draw_mobs()
  tick_crs(draw_crs)
  for _,v in pairs(glb_particles) do
    v:draw()
  end
end

function ani(_spr,l)
  return _spr+(glb_frame/8)%l
end
