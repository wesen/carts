--#include oo
--#include helpers
--#include v2
--#include bbox
--#include hitbox
--#include player
--#include tether

function _init()
  player=cls_player.init(v2(10,10))
  cls_tether.init(v2(64,28))
end

function _update()
  player:update()
  for tether in all(tethers) do
    tether:update()
  end
end

function _draw()
 cls()
 player:draw()
 for tether in all(tethers) do
   tether:draw()
 end
end
