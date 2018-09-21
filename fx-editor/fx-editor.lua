--#include oo
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
 for node in all(nodes) do
  if (node.update!=nil) node:update()
 end
end

debug_str=""

function _draw()
 frame+=1
 cls()
 for node in all(nodes) do
  if (node.draw!=nil) node:draw()
 end
 print(debug_str,0,0,7)
end
