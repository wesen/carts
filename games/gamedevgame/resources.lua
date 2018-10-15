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
  1,
  -- spr
  16,
  -- description
  "write a line of code!"
)
res_loc.active=true

resource_cls.init(
"func",
"c# functions",
 1,0,
 {loc=5},
 1,
  -- spr
  16,
  -- description
  "write a c# function!"
)

resource_cls.init(
 "csharp_file",
 "c# files",
 2,0,
 {func=5},
 1,
 -- spr
 16,
 -- description
 "write a c# file!"
)

resource_cls.init(
 "build",
 "game builds",
 2,0,
 {csharp_file=10},
 1,
 -- spr
 16,
 -- description
 "write a c# file!"
)

res_pix=resource_cls.init("pixel",
 "pixels",
  0,1,
  {},
  1,
  -- spr
  48,
  -- description
  "draw a pixel!"
)

res_spr=resource_cls.init("sprite",
 "sprites",
  1,1,
  {pixel=8},
  1,
  -- spr
  48,
  -- description
  "draw a sprite!"
)

res_anim=resource_cls.init("animation",
 "animations",
 2,1,
 {sprite=4},
 1,
 48,
 "animate a character!"
)


res_pix.active=true
