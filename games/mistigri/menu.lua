function init_menu()
 reload()
 camera()
 x=0
 t=0
 if go!=0 then
  music(0)
 end
 go=0
 mdraw=draw_menu
 
end

function draw_menu()
 if go>0 then go+=1 end
 x=(x-0.25)%128
 for i=0,1 do
  map(96,32,x+i*128-128,8+go*go,16,14)
 end
 print("mistigri",0,120,1)
 for x=0,31 do for y=0,4 do		
		dx=max(40-(t-y)*3,0)*(x-15.5)
		if pget(x,y+120)==1 then
   sspr((t+x+y)%60<4 and 4 or 0,4,4,4,2+x*4+dx,1+y*4-go*go)
  end
 end end
 rectfill(0,120,127,127,0)

 pr=t%24<16
 if go>0 then pr=t%2<1 and go<39 end
 if pr then
  print("press x to start",32,121,7)
 end
  
 dy=max(go*go/32,0)
 spr(194,56,32+dy+cos(t%64/64)*4,2,2)

  
 if btn(5) and go==0 and not fade_n then
  sfx(61)
  music(-1)
  go=1
 end 
 
 if t==512 and go==0 then
  fadeto(init_hints,true)
 end
 
 if go==64 then
  init_game()
 end
end
