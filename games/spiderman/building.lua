row_background=1
row_foreground=2
row_middleground=3
building_cols={1,13,5}
buildings={}

cls_building=class(function(self,pos,row)
 self.pos=pos
 self.row=row
 add(buildings,self)
end)

function cls_building:draw()
 rectfill(self.pos.x,122,self.pos.x+20,128-self.pos.y,building_cols[self.row])
end
