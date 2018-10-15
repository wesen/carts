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
  16,
  -- description
  "write a line of code!",
  "line of code written"
)
res_loc.active=true

res_func=resource_cls.init(
"func",
"c# functions",
 1,0,
 {loc=5},
 0.5,
  -- spr
  16,
  -- description
  "write a c# function!",
   "c# function written"
)

res_csharp_file=resource_cls.init(
 "csharp_file",
 "c# files",
 2,0,
 {func=5},
 1,
 -- spr
 16,
 -- description
 "write a c# file!",
 "c# file written"
)

--

res_pixel=resource_cls.init("pixel",
 "pixels",
  0,1,
  {},
  0.3,
  -- spr
  48,
  -- description
  "draw a pixel!",
  "pixel drawn"
)

res_sprite=resource_cls.init("sprite",
 "sprites",
  1,1,
  {pixel=8},
  0.8,
  -- spr
  48,
  -- description
  "draw a sprite!",
  "sprite drawn"
)

res_animation=resource_cls.init("animation",
 "animations",
 2,1,
 {sprite=4},
 1,
 48,
 "animate a character!",
 "character animated"
)

res_prop=resource_cls.init("prop",
 "props",
 3,1,
 {sprite=4,csharp_file=1},
 2,
 -- spr
 16,
 "make a prop!",
 "prop created"
)

res_character=resource_cls.init("character",
 "characters",
 4,1,
 {animation=4,csharp_file=3},
 4,
 -- spr
 16,
 "make a character!",
 "character created"
)

res_tilemap=resource_cls.init("tilemap",
 "tilemaps",
 0,2,
 {sprite=8},
 2,
 -- spr
 16,
 "make a tilemap!",
 "tilemap created"
)

---


res_level=resource_cls.init("level",
 "levels",
 1,2,
 {tilemap=1,prop=5,character=2,csharp_file=2},
 5,
 -- spr
 16,
 "make a level!",
 "level created"
)

res_build=resource_cls.init(
 "build",
 "game builds",
 2,2,
 {level=5,character=5},
 2,
 -- spr
 16,
 -- description
 "make a beta build",
 "game built"
)

res_build=resource_cls.init(
 "build",
 "game builds",
 2,2,
 {level=5,character=5},
 2,
 -- spr
 16,
 -- description
 "make a beta build",
 "game built"
)

res_playtest=resource_cls.init(
 "playtest",
 "playtests",
 3,2,
 {build=0},
 .5,
 -- spr
 16,
 -- description
 "playtest the beta build",
 "game tested"
)

res_release=resource_cls.init(
 "release",
 "releases",
 4,2,
 {build=5,playtest=100},
 10,
 -- spr
 16,
 -- description
 "make a release",
 "game released"
)
