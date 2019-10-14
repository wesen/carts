cls_dialogbox=class(function(self)
 self.visible=false
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

function add_box(text)
    local box=cls_dialogbox:init()
    box.text=text
    add_cr(function()
      display_box(box)
    end,draw_crs)
end

function display_box(self)
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
  self:shake(3)

  local t=time()
  while time()-t<2 and self.visible do
    init()
    update_shake(self)
    y+=self.shky

    draw_rounded_rect2(x,y+0,w,h,0,6,0)
    if #self.text>=1 then
     local txt=self.text[1][2]
     bstr(txt,64-#txt*2+self.shkx,y+3,1,6)
    end
    for i=2,#self.text do
     print(self.text[i][2],x+7,y+i*8-2,self.text[i][1])
    end
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


function cls_dialogbox:draw()
 update_shake(self)

 if not self.visible then
  self.prev_visible=self.visible
  return
 end

 local y=62
 local x=15+self.shkx
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

  draw_rounded_rect2(x,y+0,actual_w,actual_h,0,6,0)
  if (self.buildup==n) self:shake(3)
 else
  y+=self.shky

  draw_rounded_rect2(x,y+0,w,h,0,6,0)
  if #self.text>=1 then
   local txt=self.text[1][2]
   bstr(txt,64-#txt*2+self.shkx,y+3,1,6)
  end
  for i=2,#self.text do
   print(self.text[i][2],x+7,y+i*8-2,self.text[i][1])
  end
 end

 self.prev_visible=self.visible
end
