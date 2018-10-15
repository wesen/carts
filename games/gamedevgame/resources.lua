res_loc=resource_cls.init(
  -- name
  "loc",
  -- position
  0,0,
  -- dependencies
  {},
  -- duration
  10
)
res_loc.active=true

resource_cls.init("func",
 1,0,
 {loc=5},
 10
)

resource_cls.init("csharp_file",
 2,0,
 {func=5},
 10
)

res_pix=resource_cls.init("pixel",
  0,1,
  {},
  10
)
res_pix.active=true
