cls_enemy_manager=class(function(self)
 self.enemies={}
end)

function cls_enemy_manager:draw()
 foreach(self.enemies,function(e) e:draw() end)
end

function cls_enemy_manager:update()
 foreach(self.enemies,function(e) e:update() end)
end

function cls_enemy_manager:add_enemy(pos)
 add(self.enemies,cls_enemy.init(pos))
end
