function _init()
end

function _draw()
 frame+=1
 cls()
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
end
