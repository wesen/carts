birds={}
selected_bird=nil
bird_sprs={ 1,16,32 }

function get_row_y(row)
 return row*25+5
end

cls_bird=class(function(self,row,spd,col)
 self.x=128
 self.row=row
 self.spd=spd
 self.col=col
 self.angle=rnd(1)
 self.range=2+rnd(4)
 self.angle_spd=0.05+rnd(0.05)
 add(birds,self)
end)

function cls_bird:update()
 self.x-=self.spd
 self.angle+=self.angle_spd+mrnd(0.1)
end

function cls_bird:draw()
 local x0=self.x
 local y0=get_row_y(self.row)+cos(self.angle)*self.range
 local off=flr(self.spd*frame/3)%3
 spr(bird_sprs[self.col]+off,x0,y0)
end

function cls_bird:pos()
 return v2(self.x,get_row_y(self.row))
end

function get_closest_birds()
 local res={}
 local up,down,left,right=200,200,200,200

 local spos=selected_bird:pos()

 for b in all(birds) do
  if b!=selected_bird then
   local bpos=b:pos()
   local d=(bpos-spos):magnitude()

   if bpos.y<spos.y and d<up then
    res[dir_up]=b
    up=d
   end
   if bpos.y>spos.y and d<down then
    res[dir_down]=b
    up=d
   end
   if bpos.y==spos.y then
    if bpos.x>spos.x and d<left then
     res[dir_left]=b
     left=d
    end
    if bpos.x<spos.x and d<right then
     res[dir_right]=b
     right=d
    end
   end
  end
 end
 return res
end

function game_update(self)
 if rnd(1)<0.05 then
  local row=flr(rnd(3))+1
  local col=flr(rnd(3))+1
  local spd=0.3+rnd(0.8)
  cls_bird.init(row,spd,col)
 end

 if (selected_bird==nil and #birds>0) selected_bird=birds[1]
 local _birds=get_closest_birds()

 for i=0,3 do
  if btnp(i) and _birds[i]!=nil then
   selected_bird=_birds[i]
  end
 end
end
