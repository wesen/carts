cls_island=class(function(self,length)
 self.tiles_top={}
 self.tiles={}
 for i=1,length do
  add(self.tiles,rnd_elt({102,103,104,105,106}))
  add(self.tiles_top,rnd_elt({86,87,88,89,90}))
 end
 self.aax=0
 self.aay=120
 self.bbx=length*8
 self.bby=128
end)

function cls_island:draw()
 for i=1,#self.tiles do
  spr(self.tiles[i],i*8,120)
  spr(self.tiles_top[i],i*8,120-8)
 end
 -- rect(self.aax,self.aay,self.bbx,self.bby,8)
end
