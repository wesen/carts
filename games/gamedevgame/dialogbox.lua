cls_dialogbox=class(function(self)
 self.visible=true
 self.text={}
 self.shkx=0
 self.shky=0
end)

glb_dialogbox=cls_dialogbox.init()

function cls_dialogbox:shake(p)
 shake(self,p)
end


function cls_dialogbox:draw()
 update_shake(self)
 
 local y=62
 local x=15+self.shkx
 if (not self.visible) return

 if (glb_mouse_y>56) y=8
 local h=14+(#self.text-1)*8

 y+=self.shky

 draw_rounded_rect2(x,y+0,98,h,12,1,6)
 if #self.text>=1 then
  local txt=self.text[1][2]
  bstr(txt,64-#txt*2+self.shkx,y+3,1,7)
 end
 for i=2,#self.text do
  print(self.text[i][2],x+7,y+i*8-2,self.text[i][1])
 end
end
