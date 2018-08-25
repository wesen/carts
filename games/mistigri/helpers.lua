function lget(x,y)
 return mget((lvl%8)*16+x,flr(lvl/8)*16+y)
end

function lset(x,y,n)
 return mset((lvl%8)*16+x,flr(lvl/8)*16+y,n)
end

function mod(md,lp)
 return flr(t/md)%lp
end

function steal(a)
 local p=a[rand(#a)+1]
 del(a,p)
 return p
end

function rand(n)
 return flr(rnd(n))
end

function sgda(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
 return atan2(dx,dy)
end

function dst(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
	return sqrt(dx*dx+dy*dy)
end

function hmod(n,md)
 n+=md
 n=n%(md*2)
 n-=md
 return n
end
