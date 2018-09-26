function tick_crs(crs_)
 for cr in all(crs_) do
  if costatus(cr)!='dead' then
   local status,err=coresume(cr)
   if (not status) printh("cr error "..err)
  else
   del(crs_,cr)
  end
 end
end

function add_cr(f,crs_)
 local cr=cocreate(f)
 add(crs_,cr)
 return cr
end

function cr_wait_for(t)
 while t>0 do
  t-=dt
  yield()
 end
end
