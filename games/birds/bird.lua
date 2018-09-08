birds={}
selected_bird=nil
bird_sprs={ 32,16,1 }

function get_row_y(row)
 return row*25+5
end

cls_bird=class(function(self,row,spd,col)
 self.x=128
 self.row=row
 self.spd=spd
 self.col=col
 self.angle=rnd(1)
 self.range=2+rnd(2)
 self.angle_spd=0.05+rnd(0.05)
 add(birds,self)
end)

function cls_bird:update()
 self.x-=self.spd
 self.angle+=self.angle_spd+mrnd(0.1)
 if self.x<19 then
  if self.row==self.col then
   game.score+=1
  else
   game.losses+=1
  end
  del(birds,self)
  if self==selected_bird then
   local _birds=get_closest_birds()
   local dirs={dir_right,dir_down,dir_up}
   for i=1,3 do
    local dir=dirs[i]
    if selected_bird!=nil and _birds[dir]!=nil then
     selected_bird=_birds[dir]
    end
   end
  end
 end
end

function cls_bird:draw()
 local x0=self.x
 local y0=get_row_y(self.row)+cos(self.angle)*self.range
 local off=flr(self.spd*frame/3)%3
 spr(bird_sprs[self.col]+off,x0,y0)
 if self==selected_bird then
  line(x0+2,y0+10,x0+6,y0+10,7)
  line(x0+2,y0-2,x0+6,y0-2,7)
  line(x0-2,y0+2,x0-2,y0+6,7)
  line(x0+10,y0+2,x0+10,y0+6,7)
 end
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
    down=d
   end
   if bpos.y==spos.y then
    if bpos.x<spos.x and d<left then
     res[dir_left]=b
     left=d
    end
    if bpos.x>spos.x and d<right then
     res[dir_right]=b
     right=d
    end
   end
  end
 end
 return res
end
