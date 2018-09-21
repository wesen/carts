--#include oo
--#include strings
--#include rpc
--#include nodes

function _init()
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
 local i=0
 for idx,node in pairs(nodes) do
  print(tostr(idx).."("..tostr(node.id)..") "..node:str(),20,i*6+10)
  i+=1
 end
 print(debug_str,0,0,7)
end
