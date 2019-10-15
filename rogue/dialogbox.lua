glb_dialogbox={
  visible=false,
  text={},
  shkx=0,shky=0
}

function show_box(text)
  glb_dialogbox.text=text
  add_cr(function()
    display_box(glb_dialogbox)
  end,glb_draw_crs)
end

function display_box(self)
  printh("display_box "..tostr(self.visible))
  if (self.visible) return
  local x,y,h,w
  self.visible=true

  init=function()
    y=62
    x=15+self.shkx
    h=14+(#self.text-1)*8
    w=98
  end

  n=8
  for i=1,n do
    init()

    local actual_h=inexpo(i,0,h+20,n)
    local actual_w=inexpo(i,0,120,n)
    y+=h/2-actual_h/2
    x+=w/2-actual_w/2

    draw_rounded_rect2(x,y+0,actual_w,actual_h,0,6,0)
    yield()
  end
  shake(glb_dialogbox,3)

  local t=time()
  while self.visible do
    init()
    update_shake(self)
    y+=self.shky

    draw_rounded_rect2(x,y+0,w,h,0,6,0)
    if #self.text>=1 then
      local txt=self.text[1][2]
      bstr(txt,64-#txt*2+self.shkx,y+3,1,self.text[1][1])
    end
    for i=2,#self.text do
      print(self.text[i][2],x+7,y+i*8-2,self.text[i][1])
    end
    bstr("❎",x+w-12,y+h-3+sin(time()*2),1,6)
    yield()
  end

  self.visible=false

  for i=8,1,-1 do
    init()

    local actual_h=inexpo(i,0,h+20,n)
    local actual_w=inexpo(i,0,120,n)
    y+=h/2-actual_h/2
    x+=w/2-actual_w/2

    draw_rounded_rect2(x,y+0,actual_w,actual_h,0,6,0)
    yield()
  end
end
