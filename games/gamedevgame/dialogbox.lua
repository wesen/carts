cls_dialogbox=class(function(self)
 self.visible=true
 self.text={}
end)

glb_dialogbox=cls_dialogbox.init()

function cls_dialogbox:draw()
 if (not self.visible) return

 draw_rounded_rect2(15,75,98,40,12,1,6)
 if #self.text>=1 then
  local txt=self.text[1][2]
  bstr(txt,64-#txt*2,80,1,7)
 end
 for i=2,#self.text do
  print(self.text[i][2],15+7,75+i*8,self.text[i][1])
 end
end
