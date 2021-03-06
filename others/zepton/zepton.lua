-- zepton 0.9.2
-- a game by rez

function _init()
	cls""
	cartdata"zepton"
	dbg=dget"8">0
	inv=dget"9">0
	mse=dget"10">0
	if(mse) poke(0x5f2d,1)
	md={}
	for i=0,7 do
		md[i]={x=0,y=0}
	end
	fps={}
	for i=0,23 do fps[i]=0 end
	f,d=128,512 --focale/depth
	nx,nz=40,48 --voxel size
	s,si=0,0 --speed
	u,u2,u3,u4,uh=8,16,24,32,4
	uz=d/nz --depth unit
	shp,su,su2,suh={},1,2,0.5
	local n=0
	for k=0,1 do
		for j=0,6 do
			for i=0,6 do
				c=sget(8*k+i,j+16)
				if c!=0 then
					v={
						t=0,c=c,
						x=(i-3.5)*su,
						y=-(k+1)*su,
						z=(j-3.5)*su,
						w=su,h=su}
					if(c==6 or c==9 or c==8) v.t=1
					if(c==14) v.w=suh v.x+=suh/2
					shp[n]=v
					n+=1
				end
			end
		end
	end
	scr={} --score
	for i=0,7 do
		scr[i]=dget(i)
	end
	menuitem(1,"new game",
		function() init(0) end)
	menuitem(2,"score",
		function() init(2) end)
	menuitem(3,"reset score",
		function()
			for i=0,7 do
				scr[i]=0
				dset(i,0)
			end
			init(2)
		end)
	menuitem(4,"button/mouse",mc)
	menuitem(5,"invert y-axis",ya)
	--menuitem(6,"debug mode",db)
	init(1)
end

function init(m)
	mode=m --o=game/1=menu/2=score
	t,tw,tb=0,16,time()*32 --timer
	fc=0 --frame count
	tv,tz,tn={},{},0 --terrain
	px,py,pz=0,0,0
	sx,sy,sz,se,sh=0,11*u,3.5*uz,100,0
	ix,iy=0,0
	mx,my,mz,mt,ms=0,0,0,false,0
	msl,mn,mp={},0,0 --missile
	bul,bn,bp,bf={},0,0,0 --bullet
	lbod,lbt=false,false --lbod
	foe,er={},16 --enemy
	lsr,lr={},128 --laser
	smo,exp,sta={},{},{}
	cs=0 --camera shake
	lvl=0 --level
	if mode==0 then
		sc,sn=0,32
		for i=0,sn-1 do
			sta[i]={
				x=flr(rnd(128)),
				y=flr(rnd(48))}
		end
		-------------------init voxel
		for i=0,nz-1 do
			tv[i]=voxel(tn)
			tz[i]=i*uz
			if(i%er==0) spawn(i)
			tn+=1
		end
	else ----------------init menu
		sn=384
		for i=0,sn-1 do
			local v={
				z=256/sn*i,
				r=32+rnd(480),a=rnd(1),
				t={}}
			local a=v.a+0.25 --cos(0)/4
			local x,y,z=
				v.r*cos(a)+128,
				v.r*sin(a)+128,
				v.z%256
			local zf=1/z*32
			x,y=x*zf,y*zf
			for j=0,5 do
				v.t[j]={x=x,y=y,z=z}
			end
			sta[i]=v
		end
		for i=0,7 do
			a=1/6*i
			for j=0,11,2 do
				local b=j<6 and 1/28 or 1/24
				sta[sn+i*12+j]={
					x=0,y=0,a=1/6*j+a-b}
				sta[sn+i*12+j+1]={
					x=0,y=0,a=1/6*j+a+b}
			end
		end
	end
	music(m==0 and -1 or (m==1 and 0 or 8))
end

function voxel(a)
	local az,l,py=
		a%nz,{},max(6*u-a/2,o)
	local p,bx,rx=27,13,36
	local cl={7,10,9,4,5,3,3,1}
	for j=0,nx-1 do
		----------------------terrain
		local y=py
		y+=u2*cos(4/nz*min(a%nz,nz/4))
		y+=u2*cos(3/nx*j) --x
		y+=u2*sin((a-j*4)/nz) --y
		y+=u3*sin((2/nz)*(a+j))
		y=flr(min(u2+y,u4)/uh)*uh
		local c=cl[flr(max((u4+y)/8,1))]
		local bt,by,bw,bh,bc=0,u4,1,u,0
		----------------------volcano
		local vy=-u4
		if y<vy then
			if y>vy-u then
				y,c=vy+u,6
			else --lava!
				y,c=vy+u2,8
				by,bc=y-(7+rnd(6)*u),6
				bw,bt=u/16+rnd(u2)/32,1
			end
		end
		------------------------river
		if (j==p-1 or j==p+2)
		and y<u4 then
			c=a%4<2 and 6 or 13
		end
		if(j>p-1 and j<p+2) y,c=u4,1
		-----------------------bridge
		if py<u2 then
			local ry=py+cos(2/nz*max(az,nz/2))*u
			if abs(j-bx)<2 then
				y=max(y,ry+u)
				if j==bx-1 then
					by,bw,bc=ry,3,13
				end
				if j==bx and a%2==0 then
					by,bw,bc,bt=ry-uh,0.25,7,1
				end
				if y>ry and a%8==0 then
					y,c=ry+u,6
				else
					y=max(y,ry)
				end
			end
			if j==bx-2 or j==bx+2 then
				if y>ry and a%16==0 then
					y,c,by,bc=ry-u2,6,ry-u3,5
				end
				if y<ry then --wall
					c=a%4<2 and 6 or 13
				end
			end
		end
		l[j]={
			x=(j-nx/2)*u,y=y,w=1,c=c,
			by=by,bw=bw,bh=bh,bc=bc,
			bt=bt,e=false}
	end
	--------------------------road
	if abs(az-rx)<2 and py==0 then
		for j=0,nx-1 do
			v=l[j]
			if abs(j-bx)>2
			and v.y<u then --tunnel
				v.by=v.y
				v.bh,v.bc=-v.y+u,v.c
			end
			v.y,v.c=u3,13
			if j>p-2 and j<p+3 then
				v.y,v.c=u4,1 --water
			end
			if j==p-2 or j==p+3 then
				v.y=u3
				v.by,v.bh,v.bc=u2+uh,uh,5
			end
			if j==p-1 or j==p+2 then
				v.y,v.c=u3,6
				v.by,v.bc=u2,5
			end
			if j==p then
				v.by,v.bw,v.bc=u+uh,2,5
			end
		end
	end
	if az==rx-1 or az==rx+2 then
		for j=0,nx-1 do
			v=l[j]
			if v.y<u and abs(p-bx)>1 then
				v.by=v.y
				v.bh,v.bc=-v.y+u,v.c
				v.y,v.c=u,6
			end
		end
	end
	-----------------------objects
	if py==0 then
		obj(l,20,38,32) --tower
		obj(l,16,18,0)  --airport
		obj(l,2,10,16)  --pyramid
	end
	vopt(l)         --optimize
	return l
end

function obj(l,p,n,o)
	local az=tn%nz
	if az>n and az<n+9 then
		for j=0,7 do
			local x,y=j+o+8,n+8-az
			local v,c=l[p+j],sget(j+o,y)
			if c!=0 then
				v.y,v.c=(4-sget(x,y))*u,c
			end
			y+=8
			c=sget(j+o,y)
			if c!=0 then
				v.by,v.bc=(4-sget(x,y))*u,c
			end
		end
	end
end

function vopt(l)
	local p,y,c=1,false,false
	for j=0,nx-1 do
		local v=l[j]
		if v.y==y and v.c==c then
			p+=1
		else
			p,y,c=voptl(l,p,j),v.y,v.c
		end
	end
	voptl(l,p,nx)
end

function voptl(l,p,j)
	if p>1 then
		l[j-p].w=p
		for k=j-p+1,j-1 do
			l[k].w,l[k].c=1,1
		end
		return 1
	end
	return p
end

function aam()
	local x=mn%2>0 and suh or -suh
	local v={
		x=-sx+x,y=-sy,z=sz,
		vx=x/2,vy=suh/2,vz=0.125,
		t={x=mx,y=my,z=d,
			w=0,h=0,l=false}
		}
	if(mt) v.t=mt
	add(msl,v)
	mn+=1
	sfx(2)
end

function fire()
	local x,y,z=
		bn%2>0 and su2 or -su2,
		bn%2>0 and ix4 or -ix4,
		sz+4*su+rnd(0.75)*uz
	add(bul,{x=-sx+x,y=-sy-y,z=z})
	smoke(x,y-su,z,0,13)
	bn,bf=bn+1,2
	sfx(1)
end

function spawn(i)
	local j,y,w,h=
		flr(4+rnd(nx-8)),
		-(5+rnd(16))*u,
		2+flr(rnd(8+lvl)),
		2+flr(rnd(8+lvl))
	local e={
		e=(w+h)*5,    --energy
		f=(w+h)*5,    --force
		k=false,
		l=false,      --lock
		t=t,          --time
		x=(-nx/2+j)*u+uh,y=y,z=tz[i],
		w=w*su,h=h*su,
		py=y,
		vy=su/4,
		ry=1.03125,
		lf=0,         --laser flash
		bl=8+rnd(16), --bolt length
		bt=rnd(232),  --bolt time
		a=rnd(360),
		v=tv[i][j]}
	add(foe,e)
	tv[i][j].e=e
end

function enemy(e)
	local zf=1/e.z*f
	local zu=zf*su2
	local x,y,w,h,g=
		(px+e.x)*zf,(py+e.y)*zf,
		e.w*zf-zu-1,e.h*zf-zu-1,
		(py+e.v.y)*zf
	local c={0,1,2,4,8,9,10,7}
	color(0)
	rectfill(x+w,y+zu,x-w,y-zu)
	rectfill(x+zu,y+h,x-zu,y-h)
	circfill(x,y,uh*zf)
	circfill(x-w,y,zu)
	circfill(x+w,y,zu)
	circfill(x,y-h,zu)
	circfill(x,y+h,zu)
	if e.lf>0 then
		circfill(x,y,zu,c[flr(e.lf)])
		e.lf-=0.25
	end
	if e.e>0 and zu>1 then
		if t%64<32 and e.w>6*su then
			circfill(x-w,y,zu/2,12)
			circfill(x+w,y,zu/2,12)
		end
		if t%64>31 and e.h>6*su then
			circfill(x,y-h,zu/2,12)
			circfill(x,y+h,zu/2,12)
		end
	end
	if e.e>0 and e.y>-16*u ---bolt
	and t%256>=e.bt
	and t%256<e.bt+e.bl then
		local n,x1,y1=16,x,y+h+zu*2
		line(x,y1,x,g,12)
		circfill(x1,y1,zu/2,7)
		for i=1,n do
			local x2,y2=
				x1+rnd(4*zu)-2*zu,
				y1+((e.v.y-e.y)/n*zf)
			line(x1,y1,x2,y2,7)
			x1,y1=x2,y2
		end
		if t%256>e.bt+e.bl-1 then
			e.bl,e.bt=
				4+rnd(28),
				rnd(256-e.bl)
		end
	end
end

function ec(e,x,y)
	if e then
		local w,h=abs(e.x-x),abs(e.y-y)
		return (w<e.w and h<su2)
		or (h<e.h and w<su2)
		or (w<uh and h<uh)
	end
end

function boom(x,y,z,w)
	add(exp,{
		x=x,y=y,z=z,w=w,
		vx=(rnd(16)-8)/32,
		vy=(rnd(16)-8)/32,
		vz=(rnd(16)-8)/32})
end

function ex(x,y,z)
	for i=0,15 do
		boom(x,y,z,(8+rnd(4))/16*u)
	end
	sfx(3,-1,8/d*z)
	cs=2/d*(d-sz-z)
end

function smoke(x,y,z,w,c)
	add(smo,{
		i=0,
		x=x,y=y,z=z,w=w,c=c,
		vx=(rnd(12)-6)/256,
		vy=(rnd(12)-6)/256,
		vz=0})
end

function tc(i,j,y,z)
	local v=tv[i][j]
	if v and z>tz[i] then
		if(y>v.y) return 1
		if(y>v.by and y<v.by+v.bh) return 2
	end
	return 0
end

function tf(j,x,y,z)
	local j=flr((x+nx/2*u)/u)
	for i=pz,nz-1 do
		if tc(i,j,y,z)!=0 then
			return i
		end
	end
	for i=0,pz-1 do
		if tc(i,j,y,z)!=0 then
			return i
		end
	end
	return 0
end

function tk(i,j,y,z)
	local v,c=tv[i][j],tc(i,j,y,z)
	if v.w>1 then
		local b=tv[i][j+1]
		b.w,b.y,b.c=v.w-1,v.y,v.c
	end
	if c==1 then
		v.y=y+u
		--if v.by+v.bh<v.y then
		--	v.by=u4
		--end
		v.y=y+u
		v.by,v.bh,v.bc,v.bt=y+uh,u,0,0
	elseif c==2 then
		if v.bc==0 then
			v.by=y+uh
			v.y=y+u
		else
			v.by=u4
		end
	end
end

function dead()
	se,s,tw=0,0.5,32
	ex(-sx,-sy,sz)
	if(mt) mt.e=0
	for i=0,7 do --update score
		if sc>scr[i] then
			for j=6,i,-1 do
				scr[j+1]=scr[j]
			end
			scr[i]=sc
			for i=0,7 do --save score
				dset(i,scr[i])
			end
			return
		end
	end
end

function game()
	px,py=sx*0.9375,sy*0.9375+u2
	local x,y,z,zf,zu,r,x2,z2
	local a=t/10
	local cx=-64+sx/4--+cs*cos(a)
	local cy=-48+sy/4+cs*sin(a)
	ch=cy+120
	camera(cx,cy)
	clip(0,0,128,121)
	---------------------------sky
	y=u2/d*f
	local w,h,y2,c=cx+127,2,y,
		{15,14,13,5,1}
	for i=0,5 do
		color(c[i])
		rectfill(w,y2,cx,y2-h-1)
		line(w,y2+2,cx,y2+2)
		y2-=h
		h*=1.5
	end
	rectfill(w,cy,cx,y2)
	-----------------------horizon
	line(w,y-1,cx,y-1,7)
	line(w,y,cx,y,12)
	---------------------------sea
	line(w,y+1,cx,y+1,13)
	rectfill(w,ch,cx,y+2,1)
	-------------------------stars
	c={7,6,13,13}
	for i=0,sn-1 do
		v=sta[i]
		if(i%8==0) color(c[i/8+1])
		pset(
			cx+(v.x-cx-sx/4)%128,
			v.y-56+y)
	end
	-----------------------planets
	x=-sx/8
	spr(14,x-8,y-24,2,2) --moon
	x=-sx/6
	spr(42,x-40,y-17,4,2) --sun
	spr(47,x+8,y-32) --mercury
	spr(46,x+40,y-24) --venus
	x=-sx/4
	spr(62,x-84,y-19) --titan
	spr(63,x-48,y-40) --neptune
	-------------------------voxel
	for i=pz-1,0,-1 do dt(i) end
	for i=nz-1,pz,-1 do dt(i) end
	---------------------explosion
	c={7,10,9,8,4,5,13,6}
	for v in all(exp) do
		zf=1/v.z*f
		circfill(
			(px+v.x)*zf,
			(py+v.y)*zf,
			v.w*zf,
			c[min(flr(12/v.w),7)])
	end
	------------------------bullet
	for b in all(bul) do
		for i=0,3 do
			zf=1/(b.z+(2-i)*su)*f
			x,y=(px+b.x)*zf,(py+b.y)*zf
			w=su/8*zf
			rect(x+w,y+w,x-w,y-w,9)
		end
	end
	-----------------------missile
	c={8,8,5,9}
	for m in all(msl) do
		for i=1,4 do
			zf=1/(m.z+(3-i)*su)*f
			x,y=(px+m.x)*zf,(py+m.y)*zf
			w=su/4*zf
			rectfill(x+w,y+w,x-w,y-w,c[i])
		end
		if m.vz>suh then
			zf=1/(m.z-su2)*f
			circfill(
				(px+m.x)*zf,
				(py+m.y)*zf,su*zf,10)
		end
	end
	------------------------smoke1
	for v in all(smo) do
		if v.z>sz then
			ds(v.x,v.y,v.z,v.w,v.c)
		end
	end
	-------------------------laser
	for l in all(lsr) do
		for i=0,3 do
			r=l.r+i*2
			zf=1/(l.z-r*cos(l.a))*f
			circfill(
				(px+l.x+r*sin(l.a))*zf,
				(py+l.y+r*sin(l.b))*zf,
				su*zf,8)
		end
	end
	--------------------------lbod
	z=ec(mt,-sx,-sy) and mz or d
	zf,z2=1/(sz+su2)*f,1/z*f
	if lbod and mz>sz and se>0 then
		for i=0,5 do
			r=-0.9+i*0.3
			line(
				(px-sx+r)*zf,(py-sy)*zf,
				(px-sx+r)*z2,(py-sy)*z2,8)
		end
		sfx(6)
	end
	---------------------spaceship
	if se>0 then
		for i=0,count(shp) do
			v=shp[i]
			zf=1/(sz-v.z)*f
			zu=zf*suh
			x=(v.x+px-sx+v.z*ix4)*zf
			y=(v.y+py-sy-v.x*ix4+v.z*iy4)*zf
			if v.t==0 then
				w,h=v.w*zf-1,v.h*zf-1
				rectfill(x+w,y+h,x,y,v.c)
			elseif v.c==6 then --canon
				circfill(x+zu,y+zu,zu,6)
			elseif v.c==9 then --reactor
				w=zu-4
				spr(s<0.5 and 35 or 34,x+w,y+w)
			elseif bf>0 then --flame
				w=zu-4
				spr(36+flr(rnd(4)),x+w,y+w,1,1)
				bf-=1
			end
		end
		if sh>0 then ----------shield
			zf=1/sz*f
			x,y,w=
				(px-sx)*zf,(py-sy)*zf,
				sh*su*zf
			circfill(x,y,w,12)
			circfill(x,y,w/3*2,6)
			circfill(x,y,w/3,7)
		end
	end
	------------------------smoke2
	for v in all(smo) do
		if v.z<=sz then
			ds(v.x,v.y,v.z,v.w,v.c)
		end
	end
	------------------------target
	c=11
	color(c)
	if my<-u4 then -----air to air
		if mt and mt.e>0 then
			zf=1/mt.z*f
			x,y,w,h=
				(px+mt.x)*zf,
				(py+mt.y)*zf,
				max(suh,mt.w)*zf,
				max(suh,mt.h)*zf
			if(mt.l) c=8
			pal(8,c) --lock
			spr(12,x-w-1,y-h-1)
			spr(13,x+w-6,y-h-1)
			spr(28,x-w-1,y+h-6)
			spr(29,x+w-6,y+h-6)
			pal()
			print(flr(mt.z-sz),x+w+3,y-2,c)
			print(-flr(-mt.e/50),x-w-5,y-2,c)
			v=(w*2+4)/mt.f*mt.e
			rect(x+w+2,y+h+4,x-w-2,y+h+3,0)
			rect(x-w-2+v,y+h+4,x-w-2,y+h+3,mt.e>mt.f/2 and 12 or 8)
			if mt.l and ms!=1 then
				sfx(0)
				ms=1
			end
		else
			ms=0
		end
	else -----------air to surface
		zf=1/mz*f
		zu=zf*u+2
		x,y=
			(px+mx-mx%u)*zf-1,
			(py+my-my%uh)*zf-1
		rect(x+zu,y+zu,x,y)
		if mz<d then
			print(flr(mz-sz),
				x+zu+2,y+zu/2-2)
		end
	end
	for m in all(msl) do
		v=m.t
		if v.l and v.y>-u4 then
			zf=(1/v.z)*f
			zu=zf*u+2
			x,y=
				(px+v.x-v.x%u)*zf-1,
				(py+v.y-v.y%uh)*zf-1
			rect(x+zu,y+zu,x,y,8)
		end
	end
	zf=1/mz*f
	x,y=(px+mx)*zf,(py+my)*zf
	r=1
	color(ec(mt,mx,my) and 8 or 11)
	if mt and mz!=d and se>0 then
		r=(mt.w+mt.h)*zf
		if not lbod then
			zf=1/(sz+u)*f
			y2=(py-sy)*zf
			x2=((px-sx)*zf-x)/(y2-y)
			for i=0,y2-y-1,2 do
				pset(x+x2*i,y+i)
			end
		end
	end
	-----------------------pointer
	for i=0,r/2,2 do
		pset(x-r+i,y)
		pset(x+r-i,y)
		pset(x,y-r+i)
		pset(x,y+r-i)
	end
	if(btn(5)) circ(x,y,r+2)
	---------------------------hud
	camera(0,0)
	rectfill(8,24,4,1,0)
	for i=0,3 do
		pset(5,1+(8*i+py+4)%24,7)
		y=1+(8*i+py)%24
		line(5,y,6,y)
	end
	line(5,13,6,13,8)
	print(flr(sy+u4),10,11,0)
	--print(flr(-sx),10,5,0)
	if(se>50) pal(8,11)
	spr(40,111,104,2,2)
	if btn(5) and not btn(4)
	or mb==1 then
		spr(10,111,106,2,1)
	end
	if btn(4) and not btn(5)
	or mb==2 then
		spr(26,mn%2==0 and 121 or 108,106)
	end
	if(lbod) spr(27,115,98)
	pal()
	-------------------------speed
	y=12*s-1
	rectfill(1,1,2,24,0)
	if y>0 then
		rectfill(1,24-y,2,24,2)
	end
	--pset(1,24-y,8)
	--pset(2,24-y,8)
	--if dbg then
	--	print("lvl="..(lvl+1),103,21,0)
	--	print("er="..er,103,27,0)
	--	print("lr="..lr,103,33,0)
	--end
	---------------------------low
	if (mt and mt.z-sz<4*uz)
	and t%16<8 then
		spr(124,48,0,4,1)
	end
	--------------------------dead
	if se<1 then
		c={0,1,2,5,8,8,8,8}
		camera(-46,-52)
		pal(8,c[4+flr(4*sin(t/64))])
		spr(77)
		spr(78,9)
		spr(79,18)
		spr(77,27)
		pal(1,0)
		spr(92,0,9,2,1)
		spr(94,20,9,2,1)
		pal()
		if tw==0 and t%64<32 then
			print("press X C",-45,63,0)
		end
	end
	---------------------------bar
	camera(0,-121)
	clip()
	rectfill(127,6,0,0,0)
	spr(48,56,0,2,1) --eagle
	spr(se>0 and 50 or 51,-1)
	nbr(se,7,1,3,100,
		(se==0 or (se<25 and t%64<32)) and -16 or 0)
	spr(54,88)
	nbr(sc,96,1,4,1000,0)
	-------------------------debug
	if dbg then
		spr(52,28)
		print(count(msl),35,1,5)
		spr(53,40)
		print(count(lsr),47,1,5)
		spr(65,72)
		print(count(smo),78,1,5)
	end
end

function dt(i)
	local zi=tz[i]
	if(zi<8) return
	local zf=1/zi*f
	local zu=zf*u
	local x,y,w,h
	if zi>d-3*uz then
		x=97+((d-zi)/uz)*2
		for j=0,15 do
			pal(j,sget(x,80+j))
		end
	end
	for j=0,nx-1 do
		local v=tv[i][j]
		if v.c!=1 then
			y=(v.y+py)*zf
			if y<ch then
				x=(v.x+px)*zf
				rectfill(
					x+v.w*zu,
					y+(u4-v.y)*zf,x,y,v.c)
				--pset(x+zu/2-1,y-1,8)
			end
		end
		if v.by<u4 then
			y=(v.by+py)*zf
			if y<ch then
				if v.bt==0 then
					x=(v.x+px)*zf
					rectfill(
						x+v.bw*zu,
						y+v.bh*zf,x,y,v.bc)
				else
					circfill(
						(v.x+px+uh)*zf,
						y+uh*zf,
						(v.bw/2)*zu,v.bc)
				end
			end
		end
		if(v.e) enemy(v.e)
	end
	pal()
	--print(i,x,y,8)
end

function ds(x,y,z,w,c)
	zf=1/z*f
	pal(6,c)
	spr(
		64+flr(rnd(2))*16+min(w*su*zf,7),
		(px+x)*zf-3,
		(py+y)*zf-3)
	pal()
end

function upd()
	local x,y,z,v
	local j=flr((-sx+nx/2*u)/u)
	s=0.0078125*(32+sy+u4)-si
	if(si>0)	si-=0.015625
	if(sh>0) sh-=1
	if(cs>0) cs-=0.0625
	if(abs(cs)<0.0625) cs=0
	if(dbg and btn(0,1)) s=0
	-------------------------level
	lvl=min(flr(t/1024),12)
	er,lr=16-lvl,128-lvl*4--*8
	-----------------------terrain
	for i=0,nz-1 do
		tz[i]-=s
		if tz[i]<s then
			tz[i]+=d
			pz+=1
			if(pz>nz-1) pz=0
			tv[i]=voxel(tn)
			if(pz%er==0) spawn(i)
			tn+=1
		end
	end
	-------------------------smoke
	if se>0 and s>0.5 then
		y=-sy-suh
		z=sz-su2-rnd(0.75)*uz
		c=6+flr(rnd(2))*7
		if t%4<2 then
			smoke(-sx-su,y+ix4,z,0.125,c)
		else
			smoke(-sx+su,y-ix4,z,0.125,c)
		end
	end
	if se<50 and se>1
	and t%flr(se/5)==0 then
		smoke(-sx+(3-rnd(6))*su,-sy,sz,0.25,0)
	end
	if t%4<2 then
		for m in all(msl) do
			if m.vz>suh then
				smoke(m.x,m.y,m.z-su2,su,8-rnd(2))
			end
		end
	end
	for v in all(smo) do
		v.i+=1
		v.x+=v.vx
		v.y+=v.vy
		v.z-=s
		if v.i<16 then
			v.w+=0.03125 --1/32
		else
			v.w-=0.015625 --1/64
		end
		if(v.z<2 or v.w<0) del(smo,v)
	end
	-------------------------enemy
	for e in all(foe) do
		e.z-=s
		if(e.z<4) del(foe,e)
		if e.e<1 then
			if(mt==e) mt=false
			if t%4<2 then
				smoke(e.x+rnd(e.w*2)-e.w,e.y,e.z,su,0)
			end
			e.y+=e.vy
			e.vy*=e.ry
			if e.y>e.v.y then --shutdown
				e.k=true
				v=e.v
				v.by,v.bc,v.bt,v.e=
					v.y,0,0,false --no ref?
				del(foe,e)
				ex(e.x,v.y,e.z)
			end
		end
		if s>0 and e.z>sz+su2
		and flr(t-e.t)%lr==0 then
			z=e.z-sz-4*uz*s
			add(lsr,{
				x=e.x,y=e.y,z=e.z,
				a=0.25+atan2(e.x+sx,z),
				b=0.25+atan2(e.y+sy,z),
				r=0})
			sfx(4)
			e.lf=7
		end
	end
	-------------------------laser
	for l in all(lsr) do
		l.z-=s
		l.r+=4
		x,y,z=
			l.x+l.r*sin(l.a),
			l.y+l.r*sin(l.b),
			l.z-l.r*cos(l.a)
		if se>0 and z<sz+su2
		and abs(-sx-x)<su2
		and abs(-sy-y)<su2 then
			del(lsr,l)
			se-=5
			si+=s*0.5
			s,sh,cs=0.125,8,1.5
			sfx(5)
			if(se<1) dead()
		end
		if(abs(x)>nx/2*u or z<4) del(lsr,l)
	end
	---------------------spaceship
	for e in all(foe) do
		if se>0 and sz>e.z
		and ec(e,-sx,-sy) then
			e.e=0
			dead()
		end
	end
	------------------------target
	mx,my,mz=-sx,-sy,d
	if my<-u4 then -----air to air
		for e in all(foe) do
			if abs(e.x-mx)<e.w+8 and
			abs(e.y-my)<e.h+8 then
				mt,mz=e,e.z
				if abs(e.x-mx)<e.w and
				abs(e.y-my)<e.h then
					mt.l=true
				end
				break
			end
		end
	else -----------air to surface
		for i=pz,nz-1 do
			v=tv[i][j]
			if -sy>v.y or (-sy>v.by
			and -sy<v.by+v.bh) then
				mz=tz[i]
				goto me
			end
		end
		for i=0,pz-1 do
			v=tv[i][j]
			if -sy>v.y or (-sy>v.by
			and -sy<v.by+v.bh) then
				mz=tz[i]
				goto me
			end
		end
		::me::
		if mz<d then
			mt={
				x=mx,y=my,z=mz,w=uh,h=uh,
				e=0,l=true}
		end
		if sz+su2>mz and se>0
		and s>0 then dead() end
	end
	if(mt and mt.z<sz+su2) mt=false
	------------------------bullet
	for b in all(bul) do
		b.z+=uz-s
		if b.y<-u4 then --air to air
			for e in all(foe) do
				if b.z>e.z
				and ec(e,b.x,b.y) then
					del(bul,b)
					boom(b.x,b.y,e.z,uh)
					if e.e>0 then
						e.e-=10
						if e.e<1 then
							ex(e.x,e.y,e.z)
							sc+=flr(e.f/5)
						else
							sc+=1
						end
					end
				end
			end
		else ----------air to surface
			local cti=tf(j,b.x,b.y,b.z)
			if cti!=0 then
				del(bul,b)
				smoke(b.x,b.y,b.z,su2,5)
				tk(cti,j,b.y,b.z)
			end
		end
		if(b.z>d) del(bul,b)
	end
	-----------------------missile
	for m in all(msl) do
		local v,x,y=m.t,0,0
		if v.l then
			z=m.vz/32
			x,y=(v.x-m.x)*z,(v.y-m.y)*z
		end
		m.x+=m.vx+x
		m.y+=m.vy+y
		m.z+=m.vz
		m.vz*=1.05
		if(v.y>-u4) v.z-=s
		if(m.z>d) del(msl,m)
		if not v.l and m.z>d/2 then
			del(msl,m)
			ex(m.x,m.y,m.z)
		end
		if m.y<-u4 then --air to air
			if abs(v.z-m.z)<m.vz
			and ec(v,m.x,m.y) then
				del(msl,m)
				ex(v.x,v.y,v.z)
				if v.e>0 then
					v.e-=50
					if(v.e<1) sc+=flr(v.f/5)
				end
			end
		else ----------air to surface
			local cti=tf(j,m.x,m.y,m.z)
			if cti!=0 then
				del(msl,m)
				ex(m.x,m.y,m.z)
				tk(cti,j,m.y,m.z)
			end
		end
	end
	--------------------------lbod
	if lbod and se>0 then
		if((t-lbt)%64==0) se-=1
		if mz!=d then
			if -sy<-u4 then --air to air
				for e in all(foe) do
					if mz+uz>e.z
					and ec(e,-sx,-sy) then
						if e.e>0 then
							e.e-=25
							if e.e<1 then
								ex(e.x,e.y,e.z)
								sc+=flr(e.f/5)
							end
						end
					end
				end
			else ---------air to surface
				z=mz+uz
				local cti=tf(j,-sx,-sy,z)
				if cti!=0 then
					smoke(-sx,-sy,z,su2,0)
					tk(cti,j,-sy,z)
				end
			end
		end
	end
	---------------------explosion
	for v in all(exp) do
		v.x+=v.vx
		v.y+=v.vy
		v.z+=v.vz-s
		v.w-=0.125
		if v.z<4 or v.w<0 then
			del(exp,v)
		end
	end
end

function menu()
	local n,c,c1,c2
	camera(-64,-64)
	rectfill(63,63,-64,-64,0)
	a=t/1080
	sf()
	if mode==1 then ----------logo
		spr(72,25,57,5,1)
		camera(-16,-55)
		n=flr(t/4)%128
		for j=0,15 do
			c1,c2=sget(n+j,64),sget(n-j,65)
			for i=0,92 do
				c=sget(i,80+j)
				if c==3 and c1!=0 then
					pset(i,j,c1)
				end
				if c==11 and c2!=0 then
					pset(i,j,c2)
				end
			end
		end
		camera(-30,-71)
		for j=0,4 do
			c1=sget(n+j,66)
			if c1!=0 then
				for i=0,67 do
					if(sget(i,72+j)==11) pset(i,j,c1)
				end
			end
		end
	else --------------------score
		for i=0,7 do tri(i) end
		camera(-44,-34)
		spr(106,0,0,5,1)
		for i=0,7 do
			local y=12+i*6
			spr(122,-8,y)
			nbr(i+1,0,y,1,1,0)
			spr(123,8,y)
			nbr(scr[i],16,y,4,1000,
				(sc!=0 and sc==scr[i] and t%64<32) and -16 or 0)
		end
	end
	camera(0)
	print("press",1,122,1)
end

function sf() --------starfield
	local c={1,2,14,15,7,8,1,5,13,12,7,8}
	local az,a1,a2,a3=
		1024*sin(a/3),cos(a)/4,
		128*cos(a),128*cos(a/2)
	for i=0,sn-1 do
		local v=sta[i]
		local b=v.a+a1--+(sx+sy)/720
		local x,y,z=
			v.r*cos(b)+a2,
			v.r*sin(b)+a3,
			(v.z+az)%256
		local zf=1/z*32
		x,y=x*zf,y*zf
		v.t[0]={x=x,y=y,z=z}
		for j=5,1,-1 do
			v.t[j]=v.t[j-1]
		end
		local p1,p2=v.t[0],v.t[5]
		if abs(p1.x-p2.x)<64
		and abs(p1.y-p2.y)<64
		and abs(p1.z-p2.z)<200
		and abs(x)<96 and abs(y)<96 then
			local k=6-flr(z/48)
			local n=i%2*6+k
			if k>2 then
				for j=k-1,1,-1 do
					p1,p2=v.t[j],v.t[j-1]
					line(p1.x,p1.y,p2.x,p2.y,c[n-j])
				end
			else
				pset(x,y,c[n])
			end
		end
	end
end

function tri(i)
	local x2,y2={},{}
	local c={8,8,8,8,8,2,1,1}
	local z=(256-i*32+1024*sin(a/3))%256
	local zf=1/z*32
	for j=0,11 do
		local r=(j<6) and 20 or 28
		local v=sta[sn+i*12+j]
		local b=v.a+cos(a)/4
		local x,y=
			r*cos(b)+128*cos(a),
			r*sin(b)+128*cos(a/2)
		x2[j],y2[j]=x*zf,y*zf
	end
	color(c[flr(z/32)])
	line(x2[6],y2[6],x2[11],y2[11])
	for j=1,5 do
		if(j%2==1) line(x2[j-1],y2[j-1],x2[j],y2[j])
		line(x2[j+5],y2[j+5],x2[j+6],y2[j+6])
	end
end

function nbr(n,x,y,l,k,o)
	for i=0,l-1 do
		spr(112+o+((n/k)%10),x+i*8,y)
		k/=10
	end
end

function ya()
	inv=not inv
	dset(9,inv and 1 or 0)
end

function mc()
	mse=not mse
	poke(0x5f2d,mse and 1 or 0)
	dset(10,mse and 1 or 0)
end

function db()
	dbg=not dbg
	dset(8,dbg and 1 or 0)
end

function _draw()
	if mode==0 then
		game()
	else
		menu()
	end
	fc+=1
	if dbg then
		camera(0,0)
		--------------------------fps
		local n=flr(stat(1)*25)
		fps[fc%24]=max(0,n)
		rectfill(126,1,103,16,0)
		print(fps[fc%24],104,2,1)
		--line(103,4,126,4,2)
		line(103,8,126,8,2)
		--line(103,12,126,12,2)
		for i=0,23 do
			local v=fps[(i+fc%24+1)%24]
			if v>0 then
				local x,y=103+i,17-v*0.16
				line(x,y,x,16,1)
				pset(x,y,v>50 and 8 or 12)
			end
		end
		--------------------------mem
		n=stat(0)*0.0234375 --24/1024
		rectfill(126,18,103,19,0)
		rectfill(102+n,18,103,19,2)
		--print(stat(0),104,21)
		--print("lbt="..(lbt and t-lbt or "-"),1,26,0)
	end
end

function _update60()
	t=flr(time()*32-tb)
	if(mode==0) upd()
	if(tw>0) tw-=1
	-------------------------input
	local xm,ym=17*u,25*u--x/y max
	mb=stat(34)
	if mse then
		sx=stat(32)*2.125
		sy=stat(33)*1.75
		md[0]={x=sx,y=sy}
		for j=7,1,-1 do
			md[j]=md[j-1]
			sx+=md[j].x
			sy+=md[j].y
		end
		sx,sy=xm-sx/8,ym-sy/8
		ix,iy=
			(md[7].x-md[0].x)/32,
			(md[7].y-md[0].y)/16
	else
		if(btn(0) and ix<4) ix+=0.25
		if(btn(1) and ix>-4) ix-=0.25
		if btn(inv and 2 or 3)
		and iy<4 then iy+=0.25 end
		if btn(inv and 3 or 2)
		and iy>-4 then iy-=0.25 end
		---------------------position
		if(ix>0) ix-=0.125
		if ix>1 and sx>xm-u3 then
			ix-=0.5
		end
		if(ix<0) ix+=0.125
		if ix<-1 and sx<-xm+u3 then
			ix+=0.5
		end
		if(iy>0) iy-=0.125
		if iy>1 and sy>ym-u3 then
			iy-=0.5
		end
		if(iy<0) iy+=0.125
		if iy<-1 and sy<0 then
			iy+=0.5
		end
		if(abs(ix)<0.125) ix=0
		if(abs(iy)<0.125) iy=0
		if abs(sx+ix)<xm then
			sx+=ix
		else
		 ix=0
		end
		if sy+iy>-u3 and sy+iy<ym then
			sy+=iy
		else
			iy=0
		end
	end
	ix4,iy4=ix/8,iy/8
	------------------------button
	if mode==0 and se>0 then
		if (btn(4) and not btn(5))
		or mb==2 then
			if(mp%32==0) aam()
			mp+=1
		else
			mp=0
		end
		if (btn(5) and not btn(4))
		or mb==1 then
			if(bp%3==0) fire()
			bp+=1
		else
			bp=0
		end
		lbod=(btn(4) and btn(5))
		or (mb==3 or mb==4)
		if lbod and not lbt then
			lbt=t
			se-=1
		end
		if(not lbod) lbt=false
	end
	if (btnp(4) or btnp(5) or mb>0)
	and tw==0 then
		if(mode==0 and se<1) init(2) return
		if(mode==1) init(0) return
		if(mode==2) init(1) return
	end
	if(btnp(4,1)) db() --debug
end
