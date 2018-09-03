 --#include oo
 --#include menu
 --#include helpers

 local menu=cls_menu.init()

 function _init()
 end

 function _update()
   if (menu.visible) menu:update()
 end

 function _draw()
  cls()
  if (menu.visible) menu:draw()
 end
