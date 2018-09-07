pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
birds={}

function add_bird(row,spd,col)
 add(birds,{
  pos=0,
  row=row,
  spd=spd,
  col=col
 })
end

function bird_update(self)
 self.pos+=self.spd
end

function bird_draw(self)
 local w=10
 local x0=128-self.pos-10
 local y0=self.row*25+5
 local x1=x0+w
 local y1=y0+w
 rectfill(x0,y0,x1,y1,self.col)
end


-->8
function _init()
 add_bird(1,0.5,12)
 add_bird(2,0.6,8)
 add_bird(3,0.7,14)
 add_house(1,8)
 add_house(2,14)
 add_house(3,12)
end

function _update()
 foreach(birds,bird_update)
end

function _draw()
 cls()
 foreach(birds,bird_draw)
 foreach(houses,house_draw)
end
-->8
houses={}

function add_house(row,col)
 add(houses,{row=row,col=col})
end

function house_draw(self)
 local w=20
 local x0=10
 local x1=x0+w
 local y0=self.row*25
 local y1=y0+w
 rect(x0,y0,x1,y1,self.col)
end
