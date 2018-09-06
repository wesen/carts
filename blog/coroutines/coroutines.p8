pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
crs={}
draw_crs={}
lasttime=time()

function _init()
 start()
end

function _update()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
end

function _draw()
 cls(15)
 tick_crs(draw_crs)
end

function add_cr(crs,f)
 add(crs,cocreate(f))
end

function tick_crs(crs)
 foreach(crs,function (cr)
  printh("cr "..tostr(cr))
  if costatus(cr)=="dead" then
   del(crs,cr)
  else
   _,err=coresume(cr)
   if err!=nil then
    printh("error in cr "..err)
    del(crs,cr)
   end
  end
 end)
end

-->8
function cr_title()
 while true do
  print("coroutines",20,64,7)
  yield()
 end
end

function start()
 add_cr(draw_crs,cr_title)
end
