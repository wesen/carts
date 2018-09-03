--#include oo
--#include v2
--#include bbox
--#include debouncer
--#include queues
--#include config
--#include logger
--#include constants
--#include hitbox
--#include menu
--#include helpers
--#include smoke
--#include room
--#include player

actors={}

logger=cls_logger.init(128)
menu=cls_menu.init()
local player=cls_player:init()
room=cls_room:init()
frame=0
dt=0
local lasttime=time()
local show_x=false
local show_y=true

function _init()
 menu.visible=false

 menu:add("hide y",
  function(self)
    if show_y then
     show_y=false
     self.text="show y"
    else
     show_y=true
     self.text="hide y"
   end
  end)
 menu:add("show x",
  function(self)
    if show_x then
     show_x=false
     self.text="show x"
    else
     show_x=true
     self.text="hide x"
   end
  end)
 local e=cls_menu_numberentry.init("gravity",function(v) gravity=v end,0.12,0,0.3,0.05)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("accel",function(v) accel=v end,0.3,0,1,0.05)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("decel",function(v) decel=v end,0.2,0,1,0.05)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("maxrun",function(v) maxrun=v end,1,0,3,0.1)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("jump_spd",function(v) jump_spd=v end,2,0,4,0.1)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("air_accel",function(v) air_accel=v end,0.2,0,.4,0.01)
 add(menu.entries,e)
 e=cls_menu_numberentry.init("air_decel",function(v) air_decel=v end,0.1,0,.4,0.01)
 add(menu.entries,e)
end

function _update60()
 dt=time()-lasttime
 lasttime=time()

 if ((btnp(3) and btn(2)) or (btn(3) and btnp(2)))  menu.visible=not menu.visible

 if (menu.visible) menu:update()
 player:update()
 for actor in all(actors) do
  actor:update()
 end
end

function _draw()
 frame+=1
 cls()
 room:draw()
 for actor in all(actors) do
  actor:draw()
 end
 player:draw()
 if show_x then
  print("spd.x",0,80,8)
  logger:draw("spd.x",-2,2,8)
  print("pos.x",0,88,9)
  logger:draw("pos.x",0,128,9)
 end
 if show_y then
  print("spd.y",0,96,10)
  logger:draw("spd.y",-2,2,10)
  print("pos.y",0,104,11)
  logger:draw("pos.y",0,128,11)
 end

 if (menu.visible) menu:draw()
end
