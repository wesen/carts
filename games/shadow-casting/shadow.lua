p={
  x=8,
  y=8
}

function _init()
  poke(24365,1)
end

glb_selected_tile={x=8,y=8}
glb_dos=16

function _draw()
  cls()
  spr(1,p.x*8,p.y*8)
  if glb_octant!=nil then
    printh(glb_octant)
    for octant=0,7 do
      if band(glb_octant,pow(2,octant))!=0 then
        draw_octant(octant)
      end
    end
  else
    for octant=0,7 do
      draw_octant(octant)
    end
  end

  local x=glb_selected_tile.x*8
  local y=glb_selected_tile.y*8
  rect(x,y,x+7,y+7,11)
end

glb_octant=nil
glb_frame=0

function _update()
  glb_frame+=1
  if stat(30) then
    local k=stat(31)
    if (k=="x") glb_octant=0
    if (k=="0") glb_octant=bxor(glb_octant,1)
    if (k=="1") glb_octant=bxor(glb_octant,2)
    if (k=="2") glb_octant=bxor(glb_octant,4)
    if (k=="3") glb_octant=bxor(glb_octant,8)
    if (k=="4") glb_octant=bxor(glb_octant,16)
    if (k=="5") glb_octant=bxor(glb_octant,32)
    if (k=="6") glb_octant=bxor(glb_octant,64)
    if (k=="7") glb_octant=bxor(glb_octant,128)
    if (k=="-") glb_dos-=1
    if (k=="+") glb_dos+=1
  end
  if (btnp(0)) p.x-=1
  if (btnp(1)) p.x+=1
  if (btnp(2)) p.y-=1
  if (btnp(3)) p.y+=1
  if (btnp(4)) glb_is_visible=(glb_is_visible+1)%2
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
  -- printh("left_slope,right_slope "..tostr(left_slope)..","..tostr(right_slope))
  for _,v in pairs(shadow_line) do
    local _ls,_rs=v[1],v[2]
    -- printh("ls "..tostr(_ls).." rs "..tostr(_rs))
    -- print_shadowline(shadow_line)
    if left_slope<_ls and left_slope>_rs then
      -- printh("left slope not visible")
      return false
    end
    if right_slope<_ls and right_slope>_rs then
      -- printh("right slope not visible")
      return false
    end
  end

  return true
end

glb_is_visibles={is_visible_full,is_visible_partial}
glb_is_visible=1

function draw_octant(octant)
  -- printh("--")
  local shadow_line={}
  for row=1,glb_dos do
    for col=0,row do
      -- printh("")
      local dx,dy=get_octant_f(row,col,octant)
      local x,y=p.x+dx,p.y-dy
      if x<16 and x>=0 and y<16 and y>=0 then
        local f=fget(mget(x,y))
        x*=8
        y*=8

        local left_slope,right_slope
        if col==0 then
          left_slope,right_slope=(row-.5)/0,(row-.5)/(col+.5)
        else
          left_slope,right_slope=(row+.5)/(col-0.5),(row-.5)/(col+.5)
        end

        -- printh(tostr(row)..","..tostr(col).." ls,rs "..tostr(left_slope)..","..tostr(right_slope))
        if band(f,1)==1 then
          -- printh("flag")
          shadow_line[#shadow_line+1]={left_slope,right_slope}
          rectfill(x,y,x+7,y+7,12)
        else
          if glb_is_visibles[glb_is_visible+1](left_slope,right_slope,shadow_line) then
            rectfill(x,y,x+7,y+7,13)
          else
            rectfill(x,y,x+7,y+7,14)
          end
        end
      end
    end
  end
end
