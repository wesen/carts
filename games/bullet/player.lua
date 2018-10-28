cls_player=class(function(self)
 self.x=64
 self.y=64
 self.hp=10
 self.spd=3
 self.spr=1
end)

function cls_player:update()
 local xdir=0
 local ydir=0
 if (btn(0)) xdir-=1
 if (btn(1)) xdir+=1
 if (btn(2)) ydir-=1
 if (btn(3)) ydir+=1

 self.x+=xdir*self.spd
 self.y+=ydir*self.spd
end

function cls_player:draw()
 spr(self.spr,self.x,self.y)
end
