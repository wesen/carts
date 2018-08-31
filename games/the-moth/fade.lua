function darken(p,_pal)
 for j=1,15 do
  local kmax=(p+(j*1.46))/22
  local col=j
  for k=1,kmax do
   if (col==0) break
   col=dpal[col]
  end
  if (col==14) col=13
  if (col==2) col=5
  if (col==8) col=5
  pal(j,col,_pal)
 end
 printh("correct red and stuff")
end

-- fade
function fade(fade_in)
 is_fading=true
 is_screen_dark=false
 local p=0
 for i=1,10 do
  local i_=i
  local time_elapsed=0
  
  if (fade_in==true) i_=10-i
  p=flr(mid(0,i_/10,1)*100)
 
  while time_elapsed<0.1 do
   darken(p,1)
   
   if not fade_in and p==100 then
    -- this needs to be set before the final yield
    -- draw will continue to be called even if we are
    -- in a coresumed cr, if i understand this correctly
    is_screen_dark=true
   end  
   
   time_elapsed+=dt
   yield()
  end
 end

 is_fading=false
end
