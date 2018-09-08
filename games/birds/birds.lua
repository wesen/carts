--#include oo
--#include v2
--#include actors
--#include globals
--#include helpers
--#include bird
--#include house
--#include game

frame=0
lasttime=time()
dt=0

game=cls_game.init()

-->8
function _init()
 cls_bird.init(1,0.1,3)
 cls_bird.init(2,0.2,1)
 cls_bird.init(3,0.15,2)
 selected_bird=birds[1]

 cls_house.init(1,1)
 cls_house.init(2,2)
 cls_house.init(3,3)
end

function _update()
 frame+=1
 dt=time()-lasttime
 lasttime=time()
 game:update()
 foreach(birds,function(b) b:update() end)
end

function _draw()
 cls()
 foreach(houses,function(h) h:draw() end)
 foreach(birds,function(b) b:draw() end)
 game:draw()
end
