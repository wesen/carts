cls_menu=class(function(self)
  self.entries={}
  self.current_entry=1
end)

function cls_menu:draw()
  local h=8 -- border
  for entry in all(self.entries) do
    h+=entry:size()
  end

  local w=48
  local left=64-w/2
  local top=64-h/2
  rect(left,top,64+w/2,64+h/2,7)
  top+=6
  local y=top
  for i,entry in pairs(self.entries) do
    local off=0
    if i==self.current_entry then
     off+=1
     spr(2,left+3,y-2)
    end
    entry:draw(left+10+off,y)
    y+=entry:size()
  end
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

function cls_menuentry:size()
  return 8
end
