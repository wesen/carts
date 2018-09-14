cls_slider=class(function(self,name,x,y,val,min_v,max_v)
 self.x=x
 self.y=y
 self.val=val
 self.min_v=min_v
 self.max_v=max_v
end)

function cls_slider:draw()
 line(self.x,self.y,self.x+20,self.y,7)
 local sx=self.x+(self.val-self.min_v)/(self.max_v-self.min_v)*20
 rectfill(sx-1,self.y-3,sx+1,self.y+3,14)
end

function cls_slider:update()
end
