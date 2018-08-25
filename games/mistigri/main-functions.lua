function _update()
 t+=1
 if tt then
  tt-=1
  if tt==0 then
   tt=nil
   flash_bg=nil
  end
 end
 if loop then
  loop() 
 end
 if nsfx then
  sfx(nsfx)
  nsfx=nil
 end
end

function _draw()
 cls()
 if mdraw then mdraw() end
 --draw_lvl()
 
 -- fade
 if fade_n then

  fade_n+=1
  n=fade_rev and fade_n or 15-fade_n
  for i=0,15 do
   pal(i,sget(8+i,4+flr(n/4)),1) 
  end
  --log(4+flr(n/4))
  if fade_n==15 then
   fade_nxt()
   fade_n=nil
   if fade_rev then
    fadeto(pal,false)
   end
  end 

 end  
 
 --[[ log 
 cursor(0,0)
 color(8+(t%8)) 
 color(8) 
 for l in all(logs) do
  print(l)
 end 
 --]]
end
