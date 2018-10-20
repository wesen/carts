cls_mouse=class(function(self)
 self.trails={}
 self.idx=1
 self.prev_x=0
 self.prev_y=0
 self.shkx=0
 self.shky=0
 self.circle_t=30
 self.circle_x=0
 self.circle_y=0
end)

function sqr(x) return x*x end

function cls_mouse:draw()
 update_shake(self)

 if glb_mouse_left_down then
  self.circle_t=1
  self.circle_x=glb_mouse_x
  self.circle_y=glb_mouse_y
  shake(self,3)
  -- cls(7)
  circfill(glb_mouse_x,glb_mouse_y,10,7)
 end

 if self.circle_t<15 then
  -- self.circle_t+=2
  self.circle_t*=1.2
  circ(self.circle_x,self.circle_y,self.circle_t,7)
  darken((15-self.circle_t)/15*30+10)
  -- pal(7,5)
 end

 local n=5
 spr(1,glb_mouse_x+self.shkx,glb_mouse_y+self.shky)
 pal()


 for i=1,n do
  local idx=(self.idx+i-1)%n
  if self.trails[idx]!=nil then
   local v=self.trails[idx]
   local x=v[1]
   local y=v[2]
   local d=sqr(glb_mouse_x-x)+sqr(glb_mouse_y-y)
   darken((n-i)*100/n/2)
   if d>20 then
    local r=i/(n/3)+1
    -- circfill(v[1],v[2],r,7)
    spr(1,v[1],v[2])
   end
  end
 end
 pal()
 -- if self.prev_x!=glb_mouse_x or self.prev_y!=glb_mouse_y then
  self.trails[self.idx]={glb_mouse_x,glb_mouse_y}
  self.idx=(self.idx+1)%n
 -- end
 self.prev_x=glb_mouse_x
 self.prev_y=glb_mouse_y
end

glb_mouse=cls_mouse.init()
