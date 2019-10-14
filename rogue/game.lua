turn_crs={}

function update_game()
  if not glb_dialogbox.visible then
    for i=0,3 do
      if btnp(i) then
        add_cmd(i+1)
      end
    end
  elseif btnp(5) then
    glb_dialogbox.visible=false
  end

  if #turn_crs==0 and #p.cmds>0 then
    do_turn()
  end

  tick_crs(turn_crs)
end

function do_turn()
  add_cr(mkcr_mob_move(mobs[2],1),turn_crs)
  add_cr(cr_player_move,turn_crs)
end

function add_cmd(cmd)
  p.cmds[#p.cmds+1]=cmd
end
