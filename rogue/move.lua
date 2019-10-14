function add_cmd(cmd)
 if #p.cmds==0 then
  add_cr(cr_player_move)
 end
 p.cmds[#p.cmds+1]=cmd
end

function get_tile_in_direction(obj,dir)
 dir=dir or {0,0}
 local ox,oy=obj.x+dir[1],obj.y+dir[2]
 local tile=mget(ox,oy)
 return fget(tile),tile,ox,oy
end

function update_game()
 for i=0,3 do
  if btnp(i) then
   add_cmd(i+1)
  end
 end
end

cmds_dir={
 {-1,0},
 {1,0},
 {0,-1},
 {0,1}
}

function cr_player_move()
 while #p.cmds>0 do
  local dir=cmds_dir[p.cmds[1]]
  local o_x,o_y=dir[1],dir[2]
  local flag,tile,tx,ty=get_tile_in_direction(p,dir)

  local tick_move=function(o_x,o_y,n)
   p.ox+=o_x
   p.oy+=o_y
   yield_n(n)
  end

  local move=function()
   sfx(63)
   p.dir=o_x<0
   for i=1,8 do
    tick_move(o_x,o_y,1)
   end
   p.x+=o_x
   p.y+=o_y
   p.bumped_t=0
  end

  local bump=function(n)
   if time()-p.bumped_t>0.25 then
    for i=1,(n or 1) do
     tick_move(o_x,o_y,1)
     tick_move(o_x,o_y,1)
     tick_move(o_x,o_y,2)
     tick_move(-o_x,-o_y,1)
     tick_move(-o_x,-o_y,1)
     tick_move(-o_x,-o_y,2)
    end
    return true
   end
  end

  if band(flag,1)~=1 then
   move()
  else
   if tile==5 then
    -- tile
    add_box({{7,"magic box"},{6,"oh wow"}})

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
    if bump(2) then
     p.bumped_t=time()
    end
   end
  end
  del(p.cmds,p.cmds[1])
  p.ox=0
  p.oy=0
 end
end
