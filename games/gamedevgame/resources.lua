res_loc=resource_cls.init(
  -- name
  "loc",
  -- full_name
  "lines of code",
  -- position
  0,0,
  -- dependencies
  {},
  -- duration
  0.3,
  -- spr
  4,
  -- description
  "write a line of code!",
  "line of code written",
  tab_game
)
res_loc.active=true

res_func=resource_cls.init(
"func",
"c# functions",
 1,0,
 {loc=5},
 0.5,
  -- spr
  106,
  -- description
  "write a c# function!",
  "c# function written",
  tab_game
)

res_csharp_file=resource_cls.init(
 "csharp_file",
 "c# files",
 2,0,
 {func=5},
 1,
 -- spr
 4,
 -- description
 "write a c# file!",
 "c# file written",
 tab_game
)

res_contract_work=resource_cls.init(
 "contract",
 "contract work",
 3,0,
 {csharp_file=2},
 2,
 -- spr
 132,
 -- description
 "do client work (+$10)",
 "",
 tab_game
)
res_contract_work.on_produced_cb=function(self)
 glb_resource_manager.money+=10
 if (self:is_visible()) make_score_particle_explosion("$",5,83,20,11,3)
end

--
res_pixel=resource_cls.init("pixel",
 "pixels",
  0,1,
  {},
  0.3,
  -- spr
  36,
  -- description
  "draw a pixel!",
  "pixel drawn",
  tab_game
)

res_sprite=resource_cls.init("sprite",
 "sprites",
  1,1,
  {pixel=8},
  0.8,
  -- spr
  202,
  -- description
  "draw a sprite!",
  "sprite drawn",
  tab_game
)

res_animation=resource_cls.init("animation",
 "animations",
 2,1,
 {sprite=4},
 1,
 74,
 "make an animation",
 "animation created",
 tab_game
)

res_prop=resource_cls.init("prop",
 "props",
 3,1,
 {animation=1,csharp_file=1},
 2,
 -- spr
 138,
 "make a prop!",
 "prop created",
 tab_game
)

res_character=resource_cls.init("character",
 "characters",
 4,1,
 {animation=2,csharp_file=1},
 6,
 -- spr
 74,
 "make a character!",
 "character created",
 tab_game
)
res_character.offset=1

res_tilemap=resource_cls.init("tilemap",
 "tilemaps",
 0,2,
 {sprite=4},
 2,
 -- spr
 36,
 "make a tilemap!",
 "tilemap created",
 tab_game
)

---

res_level=resource_cls.init("level",
 "levels",
 1,2,
 {tilemap=1,prop=5,character=2,csharp_file=1},
 5,
 -- spr
 164,
 "make a level!",
 "level created",
 tab_game
)

res_build=resource_cls.init(
 "build",
 "game builds",
 2,2,
 {level=5},
 2,
 -- spr
 4,
 -- description
 "make a beta build",
 "game built",
 tab_game
)

res_playtest=resource_cls.init(
 "playtest",
 "playtests",
 3,2,
 {build=0},
 .5,
 -- spr
 42,
 -- description
 "playtest the beta build",
 "game tested",
 tab_game
)
res_playtest.offset=1
res_playtest.is_clickable_f=function(self)
 return res_build.count>0
end

res_release=resource_cls.init(
 "release",
 "releases",
 4,2,
 {build=5,playtest=1000},
 10,
 -- spr
 42,
 -- description
 "make a release",
 "game released",
 tab_game
)

-- release resources

res_tweet=resource_cls.init(
 "tweet",
 "tweets",
 0,0,
 {build=0},
 0.5,
 -- spr
 100,
 -- description
 "write a tweet",
 "tweet written",
 tab_release
)

res_youtube=resource_cls.init(
 "youtube",
 "youtube videos",
 1,0,
 {build=0},
 3,
 -- spr
 68,
 -- description
 "produce a youtube video",
 "youtube video recorded",
 tab_release
)

res_twitch=resource_cls.init(
 "twitch",
 "twitch streams",
 2,0,
 {build=0},
 3,
 -- spr
 10,
 -- description
 "produce a twitch stream",
 "twitch stream recorded",
 tab_release
)

res_gamer=resource_cls.init(
 "gamer",
 "gamers",
 0,1,
 {tweet=5,youtube=5,twitch=5,build=0},
 3,
 -- spr
 74,
 -- description
 "recruit a gamer",
 "gamer recruited",
 tab_release
)
res_gamer.on_produced_cb=function(self)
 glb_hire_gamer:hire()
end
