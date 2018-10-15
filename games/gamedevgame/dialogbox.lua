cls_dialogbox=class(function(self)
 self.visible=true
 self.text={}
end)

glb_dialogbox=cls_dialogbox.init()

function cls_dialogbox:draw()
 local y=75
 if (not self.visible) return

 if (glb_mouse_y>50) y=5
 local h=14+(#self.text-1)*8

 draw_rounded_rect2(15,y+0,98,h,12,1,6)
 if #self.text>=1 then
  local txt=self.text[1][2]
  bstr(txt,64-#txt*2,y+3,1,7)
 end
 for i=2,#self.text do
  print(self.text[i][2],15+7,y+i*8-2,self.text[i][1])
 end
end
