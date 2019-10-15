glb_dt=0
glb_lasttime=0
glb_frame=0

p={
 x=3,y=5,sprite=240,
 ox=0,oy=0,color=10,
 cmds={},dir=false,bumped_t=0,
 atk=1,hp=4
}

function _init()
 _drw = draw_game
 _upd = update_game
 add_mob(1,7,6)
 add_mob(2,7,5)
end

function _draw()
 _drw()
end

function _update60()
 glb_dt=time()-glb_lasttime
 glb_lasttime=time()
 glb_frame+=1
 tick_crs()
 _upd()
end
