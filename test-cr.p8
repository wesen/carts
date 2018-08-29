pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
st_start_screen=0
st_end_screen=1
st_win_screen=2

state=st_start_screen

crs={}

function wait_for(t)
 local start_time=time()
 while time()-start_time<t do
  yield()
 end
end

gfx={
 x=0,y=0,s=""
}

function draw_gfx()
 print(gfx.s,gfx.x,gfx.y)
end

function move_to(s,x,y,t)
 gfx.s=s
 gfx.x=0
 gfx.y=0
 local dx=(x-gfx.x)/10
 local dy=(x-gfx.y)/10
 for i=1,10 do
  gfx.x+=dx
  gfx.y+=dy
  wait_for(t/10)
 end 
 printh("animation finished")
end

function add_cr(f)
 local cr=cocreate(f)
 add(crs,cr)
 return cr
end

function cr_set_state(s)
 state=s
 yield()
end

function tick_crs()
 for cr in all(crs) do
  if costatus(cr)!='dead' then
   coresume(cr)
  else
   del(crs, cr)
  end
 end
end

function wait_for_crs(fs)
 local crs={}
 for f in all(fs) do
  add(crs, cocreate(f))
 end
 
 while #crs>0 do
  for cr in all(crs) do
   if costatus(cr)!='dead' then
    coresume(cr)
   else
    del(crs, cr)
   end
  end
 end
end

function wait_for_button()
 while true do
  for i=1,5 do
   if btnp(i) then
    printh("button pressed")
    return i
   end
  end
  yield()
 end
end

function game_loop()
 while true do
  printh("restart game")
  set_state(st_start_screen)
  local button=0
  wait_for_crs({
   function() 
     move_to("start screen",32,32,1)
   end,
   function()
		  button=wait_for_button()
		 end})
		 
  if button==4 then
   set_state(st_win_screen)
   move_to("win screen",32,32,1)
   wait_for_button()
  else
   set_state(st_end_screen)
   move_to("end screen",32,32,1)
   wait_for_button()
  end
  
  yield()
 end
end

function _init()
 add_cr(game_loop)
end

function _update()
 tick_crs()
end

function _draw()
 cls()
 draw_gfx()
end
__gfx__
00000000055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
