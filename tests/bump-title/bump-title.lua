-- copy to 0x4300

function u_pset(x,y,val)
 local addr=0x4300+y*128/2+flr(x/2)
 local v=peek(addr,val)
 if x%2==0 then
  v=band(v,0xf0)+val
 else
  v=v%16+(val*16)
 end
 poke(addr,v)
end

function _init()
 memset(0x4300,0,128/2*10)
 cls(0)
 print("bump",0,0,7)

 local scale=4
 for y=0,5*scale do
  for x=0,128 do
   u_pset(x,y,pget(x/scale,y/scale))
  end
 end
end

function _draw()
 memcpy(0x6000,0x4300,128/2*20)
end
