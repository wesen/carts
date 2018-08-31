cls_game=class(typ_game,function(self)
 self.current_level=1
end)

function cls_game:load_level(level)
 add_draw_cr(function ()
  fade(false)
  wait_for(1)
  self.current_level=level
  actors={}
  player=nil
  moth=nil
  local l=levels[self.current_level]
  cls_room.init(l)
  for timer in all(l.timer_lights) do
   for lamp in all(room.lamps) do
    if lamp.nr==timer[1] then
     lamp.timer={timer[2],timer[3]}
    end
   end
  end

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