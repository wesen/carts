houses={}

house_sprs={64,66,68}

cls_house=class(function(self,row,col)
 self.row=row
 self.col=col
 add(houses,self)
end)

function cls_house:update()
end

function cls_house:draw()
 spr(house_sprs[self.row],10,get_row_y(self.row)-3,2,2)
end
