-- intersects a line with a bounding box and returns
-- the intersection points
-- line is a bbox representing a segment
function isect(l,b)
 local res={}

 -- check if we can eliminate the bbox altogether
 local vmin=l.aa:min(l.bb)
 local vmax=l.aa:max(l.bb)
 if b.aa.x>vmax.x or
    b.aa.y>vmax.y or
    b.bb.x<vmin.x or
    b.bb.y<vmin.y then
  return {}
 end

 local d=l.bb-l.aa

 local p=function(u)
  return l.aa+d*u
 end

 local check_y=function(u)
  if u<=1 and u>=0 then
   local y1=l.aa.y+u*d.y
   if y1>=b.aa.y and y1<=b.bb.y then
    add(res,p(u))
   end
  end
 end
 local check_x=function(u)
  if u<=1 and u>=0 then
   local x1=l.aa.x+u*d.x
   if x1>=b.aa.x and x1<=b.bb.x then
    add(res,p(u))
   end
  end
 end

 local baa=b.aa-l.aa
 local bba=b.bb-l.aa
 if d.x!=0 then
  check_y(baa.x/d.x)
  check_y(bba.x/d.x)
 end
 if d.y!=0 then
  check_x(baa.y/d.y)
  check_x(bba.y/d.y)
 end

 return res
end