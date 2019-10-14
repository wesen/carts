function get_tile_in_direction(obj,dir)
 dir=dir or {0,0}
 local ox,oy=obj.x+dir[1],obj.y+dir[2]
 if (ox<0 or ox>15 or oy<0 or oy>15) return 1,2,ox,oy

 local m=get_mob(ox,oy)
 if (m!=false) return 512,m,ox,oy

 local tile=mget(ox,oy)
 return fget(tile),tile,ox,oy
end

move_dirs={
 {-1,0},
 {1,0},
 {0,-1},
 {0,1}
}

function cr_move_mob(mob,_dir,cb)
  local dir=move_dirs[_dir]
  local o_x,o_y=dir[1],dir[2]

  local tick_move=function(o_x,o_y,n)
   mob.ox+=o_x
   mob.oy+=o_y
   yield_n(n)
  end

  local move=function()
   sfx(63)
   mob.dir=o_x<0
   for i=1,8 do
    tick_move(o_x,o_y,1)
   end
   mob.x+=o_x
   mob.y+=o_y
   mob.bumped_t=0
  end

  local bump=function(n)
   if time()-mob.bumped_t>0.25 then
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

  cb(mob,dir,move,bump)
  mob.ox=0
  mob.oy=0
end
