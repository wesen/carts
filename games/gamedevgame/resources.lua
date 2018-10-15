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

res_file=resource_cls.init(
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

res_func.created=true
res_file.created=true
res_loc.created=true

resource_cls.init(
 "build",
 "game builds",
 3,0,
 {csharp_file=10},
 2,
 -- spr
 16,
 -- description
 "write a c# file!",
 "game built"
)

res_pix=resource_cls.init("pixel",
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

res_spr=resource_cls.init("sprite",
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

res_anim=resource_cls.init("animation",
 "animations",
 2,1,
 {sprite=4},
 1,
 48,
 "animate a character!",
 "character animated"
)

res_pix.active=true
