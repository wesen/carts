--#include oo
--#include strings
--#include rpc
--#include nodes
--#include console

--#include helpers
--#include tween
--#include particles
--#include particle_nodes
--#include util_nodes
--#include emitter_nodes
--#include function_nodes

function _init()
 poke(0x5f2d,1)
end

frame=0
dt=0
lasttime=time()

function _update60()
 dt=time()-lasttime
 lasttime=time()
 dispatch_rpc()
 for _,node in pairs(nodes) do
  if (node.update!=nil) node:update()
 end
end

debug_str=""

function _draw()
 frame+=1
 cls()
 for _,node in pairs(nodes) do
  if (node.draw!=nil) node:draw()
 end
 -- local i=0
 -- for idx,node in pairs(nodes) do
 --  print(tostr(idx).."("..tostr(node.id)..") "..node:str(),20,i*6+10)
 --  i+=1
 -- end
 -- print(debug_str,0,0,7)

 draw_console()

 print(tostr(stat(1)),0, 110,7)
 print(tostr(stat(0)),0, 116,7)
end
