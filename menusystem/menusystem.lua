--#include oo
--#include menu
--#include helpers

local menu=cls_menu.init()

function _init()
  menu:add("test",function() printh("test callback") end)
  menu:add("test2",function() printh("test2 callback") end)
  menu:add("test3",function() printh("test3 callback") end)

  menuitem(1,"resume",function()
  poke(0x5f30,1)
end)

end

function _update()
  menu:update()
end

function _draw()
 cls()
 menu:draw()
end
