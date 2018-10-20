cls_dialogbox=class(function(self)
 self.visible=true
 self.text={}
 self.shkx=0
 self.shky=0
 self.prev_visible=false
 self.buildup=0
end)

glb_dialogbox=cls_dialogbox.init()

function cls_dialogbox:shake(p)
 shake(self,p)
end


function cls_dialogbox:draw()
 update_shake(self)


 if not self.visible then
  self.prev_visible=self.visible
  return
 end

 local y=62
 local x=15+self.shkx
 if (glb_mouse_y>56) y=8
 local h=14+(#self.text-1)*8
 local w=98

 if not self.prev_visible then
  self.buildup=0
 end

 local n=7
 if self.buildup<n then
  self.buildup+=1
  local actual_h=inexpo(self.buildup,0,h+20,n)
  local actual_w=inexpo(self.buildup,0,120,n)
  y+=h/2-actual_h/2
  x+=w/2-actual_w/2

  draw_rounded_rect2(x,y+0,actual_w,actual_h,12,1,6)
  if (self.buildup==n) self:shake(3)
 else
  y+=self.shky

  draw_rounded_rect2(x,y+0,w,h,12,1,6)
  if #self.text>=1 then
   local txt=self.text[1][2]
   bstr(txt,64-#txt*2+self.shkx,y+3,1,7)
  end
  for i=2,#self.text do
   print(self.text[i][2],x+7,y+i*8-2,self.text[i][1])
  end
 end

 self.prev_visible=self.visible
end
