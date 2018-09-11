local bboxvt={}
bboxvt.__index=bboxvt

function hitbox_to_bbox(hb,off)
 local lx=hb.x+off.x
 local ly=hb.y+off.y

 return bbox(v2(lx,ly),v2(lx+hb.dimx,ly+hb.dimy))
end

function bbox(aa,bb)
 return setmetatable({aax=aa.x,aay=aa.y,bbx=bb.x,bby=bb.y},bboxvt)
end

function bboxvt:w()
 return self.bbx-self.aax
end

function bboxvt:h()
 return self.bby-self.aay
end

function bboxvt:is_inside(v)
 return v.x>=self.aax
 and v.x<=self.bbx
 and v.y>=self.aay
 and v.y<=self.bby
end

function bboxvt:str()
 return tostr(self.aax)..","..tostr(self.aay).."-"..tostr(self.bbx)..","..tostr(self.bby)
end

function bboxvt:draw(col)
 rect(self.aax,self.aay,self.bbx-1,self.bby-1,col)
end

function bboxvt:to_tile_bbox()
 local x0=max(0,flr(self.aax/8))
 local x1=min(room.dim_x,(self.bbx-1)/8)
 local y0=max(0,flr(self.aay/8))
 local y1=min(room.dim_y,(self.bby-1)/8)
 return bbox(v2(x0,y0),v2(x1,y1))
end

function bboxvt:collide(other)
 return other.bbx > self.aax and
   other.bby > self.aay and
   other.aax < self.bbx and
   other.aay < self.bby
end
