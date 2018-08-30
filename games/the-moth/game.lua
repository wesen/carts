cls_game=class(typ_game,function(self)
 self.current_level=1
end)

function cls_game:load_level(level)
 printh("load level "..tostr(level))
 self.current_level=level
 actors={}
 player=nil
 moth=nil
 cls_room.init(levels[self.current_level])
 fireflies_init(room.dim*8)
 room:spawn_player()
end

function cls_game:next_level()
 self:load_level(self.current_level%#levels+1)
end

game=cls_game.init()