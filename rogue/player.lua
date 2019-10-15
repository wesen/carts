function cb_player_move(p,dir,move,bump)
  local flag,tile,tx,ty=get_tile_in_direction(p,dir)
  if band(flag,512)==512 then
    -- mob
    sfx(56)
    cr_hit_mob(p,tile)
  elseif band(flag,1)~=1 then
    move()
  else
    if tile==5 then
      -- tile
      sfx(57)
      add_box({
        {7,"welcome to porklike"},
        {6,"climb the tower"},
        {6,"to obtain the"},
        {6,"golden kielbasa"},
      },glb_dialogbox)
      p.cmds={}

      bump()
    elseif tile==6 or tile==7 then
      -- vase
      sfx(59)
      mset(tx,ty,3)
      bump()
    elseif tile==9 or tile==11 then
      -- chest
      sfx(61)
      mset(tx,ty,tile-1)
      bump()
    elseif tile==12 then
      -- door
      sfx(62)
      mset(tx,ty,3)
      move()
    else
      sfx(58)
      if bump(2) then
        p.bumped_t=time()
      end
    end
  end
  del(p.cmds,p.cmds[1])
end

function cr_player_move()
  cr_move_mob(p,p.cmds[1],cb_player_move)
end
