-- queues - *sigh*
function popend(t)
 t[#t]=nil
end

function insert(t,val,max_)
 local l=min(#t+1,max_)
 for i=l,2,-1 do
  t[i]=t[i-1]
 end
 t[1]=val
end
