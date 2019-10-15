turn_crs={}

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

  tick_crs(turn_crs)
end

function cr_game_loop()
  while true do
    if #p.cmds>0 then
      cr_player_move()
    else
      yield()
    end
  end
end

add_cr(cr_game_loop,turn_crs)
