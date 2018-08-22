
-- helpers
function clamp(val,a,b)
    return max(a,min(b,val))
end

function appr(val,target,amount)
    return (val>target and max(val-amount,target))
      or min(val+amount,target)
end

function sign(v)
    return v>0 and 1 or v<0 and -1 or 0
end

function maybe()
    return rnd(1)<0.5
end
