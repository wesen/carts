cls_menu=class(function(self)
  self.entries={}
  self.current_entry=1
end)

function cls_menu:draw()
  local h=#self.entries*8+8
  local w=48
  local left=64-w/2
  local top=64-h/2
  rect(left,top,64+w/2,64+h/2,7)
  top+=6-8
  for i,entry in pairs(self.entries) do
    local off=0
    if (i==self.current_entry) off+=1
    entry:draw(left+10+off,top+i*8)
  end
  spr(2,left+3,top-2+self.current_entry*8)
end

function cls_menu:add(text,cb)
  add(self.entries,cls_menuentry.init(text,cb))
end

function cls_menu:update()
  local e=self.current_entry
  local n=#self.entries
  self.current_entry=btnp(3) and tidx_inc(e,n) or (btnp(2) and tidx_dec(e,n)) or e
end

cls_menuentry=class(function(self,text,callback)
  self.text=text
  self.callback=callback
end)

function cls_menuentry:draw(x,y)
  print(self.text,x,y,7)
end
