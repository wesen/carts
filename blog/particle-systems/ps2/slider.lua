cls_slider=class(function(self,name,x,y,val,min_v,max_v)
 self.name=name
 self.x=x
 self.y=y
 self.val=val
 self.min_v=min_v
 self.max_v=max_v
 self.bbox={
  aax=self.x,bbx=self.x+20,
  aay=self.y-3,bby=self.y+3
 }
end)

function cls_slider:draw(mx,my,mb)
 line(self.x,self.y,self.x+20,self.y,7)
 local sx=self.x+(self.val-self.min_v)/(self.max_v-self.min_v)*20
 rectfill(sx-1,self.y-3,sx+1,self.y+3,14)

 if (in_bbox(self.bbox,mx,my)) print(self.name,0,110)
end

function in_bbox(bbox,x,y)
 return x>=bbox.aax and x<=bbox.bbx and y>=bbox.aay and y<=bbox.bby
end

function cls_slider:update(mx,my,mb)
 -- bounding box for the knob
 if mb and in_bbox(self.bbox,mx,my) then
  self.val=(mx-self.x)/20*(self.max_v-self.min_v)+self.min_v
 end
end
