
function rspr(s,x,y,angle)
 angle=(angle+4)%4
 local x_=(s%16)*8
 local y_=flr(s/16)*8
 local f=function(i,j,p)
   pset(x+i,y+j,p)
 end
 if angle==1 then
  f=function(i,j,p)
   pset(x+7-j,y+i,p)
  end
 elseif angle==2 then
  f=function(i,j,p)
   pset(x+7-i,y+7-j,p)
  end
 elseif angle==3 then
  f=function(i,j,p)
   pset(x+j,y+7-i,p)
  end
 end
 for i=0,7 do
  for j=0,7 do
   local p=sget(x_+i,y_+j)
   if (p!=0) f(i,j,p)
  end
 end
end

