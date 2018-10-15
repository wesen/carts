res_loc=resource_cls.init(
  -- name
  "loc",
  -- position
  0,0,
  -- dependencies
  {},
  -- duration
  10,
  -- spr
  16,
  -- description
  "Write a line of code!"
)
res_loc.active=true

resource_cls.init("func",
 1,0,
 {loc=5},
 10,
  -- spr
  16,
  -- description
  "Write a C# function!"
)

resource_cls.init("csharp_file",
 2,0,
 {func=5},
 10,
 -- spr
 16,
 -- description
 "Write a C# file!"
)

resource_cls.init("build",
 2,0,
 {csharp_file=10},
 10,
 -- spr
 16,
 -- description
 "Write a C# file!"
)

res_pix=resource_cls.init("pixel",
  0,1,
  {},
  10,
  -- spr
  48,
  -- description
  "Draw a pixel!"
)
res_pix.active=true
