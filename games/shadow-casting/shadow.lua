p={
  x=8,
  y=8
}
function _draw()
  cls()
  spr(1,p.x*8,p.y*8)
  for octant=0,7 do
    draw_octant(octant)
  end
end

glb_octant=0
glb_frame=0

function _update()
  glb_frame+=1
  if (btnp(0)) p.x-=1
  if (btnp(1)) p.x+=1
  if (btnp(2)) p.y-=1
  if (btnp(3)) p.y+=1
  if (btnp(4)) glb_is_visible=(glb_is_visible+1)%2
  -- if btnp(1) then
  if glb_frame%4==0 then
    -- glb_octant=(glb_octant+1)%8
  end
end

function get_octant_f(row,col,octant)
  if (octant==0) return col,-row
  if (octant==1) return row,-col
  if (octant==2) return row,col
  if (octant==3) return col,row
  if (octant==4) return -col,row
  if (octant==5) return -row,col
  if (octant==6) return -row,-col
  if (octant==7) return -col,-row
end

function print_shadowline(shadow_line)
  s=""
  for _,v in pairs(shadow_line) do
    s=s.."["..tostr(v[1])..","..tostr(v[2]).."] "
  end
  printh("shadow_line: "..tostr(s))
end

function is_visible_full(left_slope,right_slope,shadow_line)
  for _,v in pairs(shadow_line) do
    local _ls,_rs=v[1],v[2]
    if _ls>=left_slope and _rs<=right_slope then
      return false
    end
  end

  return true
end

function is_visible_partial(left_slope,right_slope,shadow_line)
  printh("left_slope,right_slope "..tostr(left_slope)..","..tostr(right_slope))
  for _,v in pairs(shadow_line) do
    local _ls,_rs=v[1],v[2]
    printh("ls "..tostr(_ls).." rs "..tostr(_rs))
    print_shadowline(shadow_line)
    if left_slope<_ls and left_slope>_rs then
      printh("left slope not visible")
      return false
    end
    if right_slope<_ls and right_slope>_rs then
      printh("right slope not visible")
      return false
    end
  end

  return true
end

glb_is_visibles={is_visible_full,is_visible_partial}
glb_is_visible=1

function draw_octant(octant)
  printh("--")
  local shadow_line={}
  for row=1,16 do
    for col=0,row do
      printh("")
      local dx,dy=get_octant_f(row,col,octant)
      local x,y=p.x+dx,p.y-dy
      if x<16 and x>=0 and y<16 and y>=0 then
        local f=fget(mget(x,y))
        x*=8
        y*=8

        local left_slope,right_slope=(row+1)/col,row/(col+1)

        printh(tostr(row)..","..tostr(col).." ls,rs "..tostr(left_slope)..","..tostr(right_slope))
        if glb_is_visibles[glb_is_visible+1](left_slope,right_slope,shadow_line) then
          if band(f,1)==1 then
            shadow_line[#shadow_line+1]={left_slope,right_slope}
            rectfill(x,y,x+7,y+7,12)
          else
            rectfill(x,y,x+7,y+7,13)
          end
        else
          rectfill(x,y,x+7,y+7,14)
        end
      end
    end
  end
end
