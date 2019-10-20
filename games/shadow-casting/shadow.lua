p={
  x=8,
  y=8
}
function _draw()
  cls()
  spr(1,p.x*8,p.y*8)
  draw_octant()
end

function draw_octant()
  for row=1,8 do
    for col=0,row do
      local x,y=p.x+col,p.y-row
      x*=8
      y*=8
      rectfill(x,y,x+7,y+7,12)
    end
  end
end
