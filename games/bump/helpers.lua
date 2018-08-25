-- functions
function appr(val,target,amount)
    return (val>target and max(val-amount,target)) or min(val+amount,target)
end

function sign(v)
    return v>0 and 1 or v<0 and -1 or 0
end

function round(x)
    return flr(x+0.5)
end

function maybe(p)
    if (p==nil) p=0.5
    return rnd(1)<p
end

function mrnd(x)
    return rnd(x*2)-x
end