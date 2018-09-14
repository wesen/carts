dragged_slider=nil
slider_vals={}

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
 self.is_dragging=false
 self:update()
end)

function fmt_dec(v)
 local fv=flr(v)
 local dec=flr((v-fv)*100)
 local res=tostr(fv)
 if (dec!=0) res=res.."."..tostr(dec)
 return res
end

function cls_slider:draw(mx,my,mb)
 line(self.x,self.y,self.x+20,self.y,7)
 local sx=self.x+(self.val-self.min_v)/(self.max_v-self.min_v)*20
 rectfill(sx-1,self.y-3,sx+1,self.y+3,14)
 print(fmt_dec(self.val),self.x+24,self.y-2,6)

 if (in_bbox(self.bbox,mx,my)) print(self.name,0,110)
end

function in_bbox(bbox,x,y)
 return x>=bbox.aax and x<=bbox.bbx and y>=bbox.aay and y<=bbox.bby
end

function cls_slider:update(mx,my,mb)
 -- bounding box for the knob
 if mb then
  if in_bbox(self.bbox,mx,my) and dragged_slider==nil then
   dragged_slider=self
  end
  if dragged_slider==self then
   local val=mid(self.min_v,
       (mx-self.x)/20*(self.max_v-self.min_v)+self.min_v,
       self.max_v)
   self.val=val
  end
 elseif dragged_slider==self then
  dragged_slider=nil
 end
 slider_vals[self.name]=self.val
end
