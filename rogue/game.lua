glb_turn_crs={}

function draw_game()
  cls(0)
  map()
  draw_mobs()
  tick_crs(glb_draw_crs)
  for _,v in pairs(glb_particles) do
    v:draw()
  end
  for _,v in pairs(glb_pwrup_particles) do
    v:draw()
  end
  los(p,{x=8,y=8})
end

function update_game()
  if not glb_dialogbox.visible then
    for i=0,3 do
      if btnp(i) then
        p.cmds[#p.cmds+1]=i+1
      end
    end
  elseif btnp(5) then
    glb_dialogbox.visible=false
  end

  tick_crs(glb_turn_crs)

  for _,v in pairs(glb_particles) do
    v:update()
  end
  for _,v in pairs(glb_pwrup_particles) do
    v:update()
  end
end

function cr_game_loop()
  while true do
    if #p.cmds>0 then
      cr_player_move()
      cr_mob_turn()
    else
      yield()
    end
  end
end

add_cr(cr_game_loop,glb_turn_crs)
