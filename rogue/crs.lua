glb_crs={}
glb_draw_crs={}

function yield_n(n)
 for i=1,n do
  yield()
 end
end

function tick_crs(_crs)
 _crs=_crs or crs
 for cr in all(_crs) do
  if costatus(cr)!='dead' then
   _,err=coresume(cr)
   if (err!=nil) printh("error: "..err)
  else
   del(_crs,cr)
  end
 end
end

function add_cr(f,_crs)
 _crs=_crs or crs
 local cr=cocreate(f)
 add(_crs,cr)
 return cr
end

function cr_wait_for_crs(crs)
  while #crs>0 do
    tick_crs(crs)
    yield()
  end
end

function cr_wait_for(t)
 while t>0 do
  yield()
  t-=glb_dt
 end
end
