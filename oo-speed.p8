pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function class(base)
  setmetatable(base, {
    __call = instantiate,
    __index = base.extends
  })
  return base
end

function instantiate(class, ...)
  local instance = {}
  setmetatable(instance,{ __index = class })
  instance:new(...)
  return instance
end

--

particle=class{
 new=function(self,args)
  self.x=args.x
  self.y=args.y
 end
}

function particle:update()
 self.x+=1
 self.y+=1
end
--

function make_particle(x,y)
 return {
   x=x,
   y=y,
   update=function(self)
    self.x+=1
    self.y+=1
   end
 }
end
 

function update_particle(p)
 p.x+=1
 p.y+=1
end

--

particles={}
particles2={}

function _init()
 for i=0,1000 do
	 local p=particle{x=10,y=10}
	 add(particles,p)
	 p=make_particle(10,10)
	 add(particles2,p)
	end
end

function _draw()
 cls()
 for p in all(particles) do
  p:update()
 end
 local cpu1=stat(1)
 for p in all(particles2) do
  p:update()
 end
 local cpu2=stat(1)
 for p in all(particles2) do
  update_particle(p)
 end
 local cpu3=stat(1)
 print("cpu "..tostr(cpu1),0,0)
 print("cpu "..tostr(cpu2-cpu1),0,8)
 print("cpu "..tostr(cpu3-cpu2),0,16)
end
