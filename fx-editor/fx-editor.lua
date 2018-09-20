--#include oo
--#include rpc
--#include nodes

function _init()
end

frame=0


function _update()
 dispatch_rpc()
 for node in all(nodes) do
  node:update()
 end
end

function _draw()
 frame+=1
 cls()
 for node in all(nodes) do
  node:draw()
 end
 print(tostr(hello_world_args[1]),64,64,7)
 print(tostr(hello_world_args[2]),64,70,7)
 print(tostr(hello_world_args[3]),64,76,7)
end
