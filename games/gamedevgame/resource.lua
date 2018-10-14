resource_cls=class(function(self,name,x,y,dependencies,duration)
 self.x=x
 self.y=y
 self.name=name
 self.dependencies=dependencies
 self.duration=duration
 self.t=0
 self.count=0
 self.active=false
 glb_resource_manager.resources[name]=self
end)

function resource_cls:draw()
 local x,y
 x,y=self:get_cur_xy()
 rect(x,y,x+40,y+40,7)
 print(tostr(self.count),x+3,y+32,7)
 if (self:is_mouse_over()) print(self.name,32,80,7)
end

function resource_cls:get_cur_xy()
 local x=self.x*42
 local y=self.y*42
 return x,y
end

function resource_cls:update()
end

function resource_cls:on_click()
 self.count+=1
end

function resource_cls:is_mouse_over()
 local x,y
 x,y=self:get_cur_xy()
 local dx=glb_mouse_x-x
 local dy=glb_mouse_y-y
 print(tostr(dx)..","..tostr(dy),x+1,y+10)
 return dx>=0 and dx<=40 and dy>=0 and dy<=40
end

resource_cls.init("line of code",
  0,0,
  {},
  10
)

resource_cls.init("function",
 1,0,
 {},
 10
)

resource_cls.init("c# file",
 2,0,
 {},
 10
)
