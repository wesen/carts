cls_game=class(function(self)
 self.score=0
 self.losses=0
end)

function cls_game:update()
 if rnd(1)<0.01 then
  local row=flr(rnd(3))+1
  local col=flr(rnd(3))+1
  local spd=0.2+rnd(0.2)
  cls_bird.init(row,spd,col)
 end

 if (selected_bird==nil and #birds>0) selected_bird=birds[1]
 local _birds=get_closest_birds()

 if btn(4) and selected_bird!=nil then
  if (btnp(dir_up) and selected_bird.row>1) selected_bird.row-=1
  if (btnp(dir_down) and selected_bird.row<3) selected_bird.row+=1
 else
  for i=0,3 do
   if btnp(i) and _birds[i]!=nil then
    selected_bird=_birds[i]
   end
  end
 end
end

function cls_game:draw()
 print("losses: "..tostr(self.losses),20,0,7)
 print("score: "..tostr(self.score),80,0,7)
end
