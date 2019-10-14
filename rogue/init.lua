dt=0
lasttime=0
glb_frame=0

p={
 x=3,y=5,sprite=240,
 ox=0,oy=0,color=10,
 cmds={},dir=false,bumped_t=time()
}

function _init()
 _drw = draw_game
 _upd = update_game
 add_mob(0,7,6)
 add_mob(4,7,5)
end

function _draw()
 _drw()
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 glb_frame+=1
 tick_crs()
 _upd()
end
