cls_game=class(typ_game,function(self)
 self.current_level=1
end)

function cls_game:load_level(level,skip_fade)
 add_draw_cr(function ()
  if not skip_fade then
   fade(false)
   wait_for(1)
  end
  self.current_level=level
  actors={}
  player=nil
  moth=nil
  local l=levels[self.current_level]
  cls_room.init(l)

  fireflies_init(room.dim)
  room:spawn_player()
  fade(true)
  music(0)
  end)
end

function cls_game:next_level()
 music(-1,300)
 sfx(39)
 self:load_level(self.current_level%#levels+1)
end

game=cls_game.init()