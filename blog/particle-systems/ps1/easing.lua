-- b: beginning value
-- c: end value
-- t: current time
-- d: duration
function inoutcubic(b,c,t,d)
 t/=d
 local ts=t*t
 local tc=ts*t
 return b+c*(-2*tc+3*ts)
end

function incirc(b,c,t,d)
 t/=d;
 return -c*(sqrt(1-t*t)-1)+b;
end
