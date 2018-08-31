frame=0
dt=0
lasttime=time()
room=nil

actors={}
tiles={}
crs={}
draw_crs={}

moth=nil
player=nil

levels={
 {pos=v2(0,16),dim=v2(16,16)},
 {pos=v2(16,0),dim=v2(32,16)},
 {pos=v2(0,0),dim=v2(16,16)}
}

is_fading=false
is_screen_dark=false