glb_particles={}
glb_pwrup_particles={}

cls_particle=class(function(self,pos,lifetime,sprs)
 self.x=pos.x+mrnd(1)
 self.y=pos.y
 add(glb_particles,self)
 self.flip_h=false
 self.flip_v=false
 self.t=0
 self.lifetime=lifetime
 self.sprs=sprs
 self.weight=0
end)

function cls_particle:random_flip()
 self.flip_h=maybe()
 self.flip_v=maybe()
end

function cls_particle:random_angle(spd)
 local angle=rnd(1)
 self.spd_x=cos(angle)*spd
 self.spd_y=sin(angle)*spd
end

function cls_particle:update()
 self.aax=self.x+2
 self.bbx=self.x+4
 self.aay=self.y+2
 self.bby=self.y+4
 self.t+=glb_dt

 if self.t>self.lifetime then
   del(glb_particles,self)
   return
 end

 self.x+=self.spd_x
 self.aax+=self.spd_x
 self.bbx+=self.spd_x
 self.y+=self.spd_y
 self.aay+=self.spd_y
 self.bby+=self.spd_y
 self.spd_y=appr(self.spd_y,2,0.12)
end

function cls_particle:draw()
 local idx=flr(#self.sprs*(self.t/self.lifetime))
 local spr_=self.sprs[1+idx]
 spr(spr_,self.x,self.y,1,1)
end

cls_score_particle=class(function(self,x,y,val,c2,c1)
 self.x=x
 self.y=y
 self.spd_x=mrnd(0.2)
 self.spd_y=-rnd(0.2)-0.4
 self.c2=c2
 self.c1=c1
 self.val=val
 self.t=0
 self.lifetime=1
 if (#glb_particles>20) return
 add(glb_particles,self)
end)

function cls_score_particle:update()
 self.t+=glb_dt
 self.x+=self.spd_x+rnd(.1)
 self.x=mid(rnd(5),self.x,128-rnd(5)-4*#self.val)
 self.y+=self.spd_y
 if (self.t>self.lifetime) del(glb_particles,self)
end

function cls_score_particle:draw()
 bstr(self.val,self.x,self.y,self.c1,self.c2)
end

function make_score_particle_explosion(s,n,x,y,c2,c1,spread_x,spread_y)
 spread_x=spread_x or 10
 spread_y=spread_y or 8
 for i=1,n do
  local p=cls_score_particle.init(x+mrnd(spread_x),y+mrnd(spread_y),s,c2,c1)
  p.spd_y*=1
  p.lifetime=2
 end
end

function make_mouse_text_particle(text,c2,c1)
 cls_score_particle.init(mid(glb_mouse_x+5-(#text/2)*4,5,80),glb_mouse_y+2,
  text,0,7)
end

cls_pwrup_particle=class(function(self,x,y,a,cols)
 self.spd_x=cos(a)*.8
 self.cols=cols
 self.spd_y=sin(a)*.8
 self.x=x+self.spd_x*5
 self.y=y+self.spd_y*5
 self.t=0
 self.lifetime=0.8
 add(glb_pwrup_particles,self)
end)

function cls_pwrup_particle:update()
 self.t+=glb_dt
 self.y+=self.spd_y
 self.x+=self.spd_x
 self.spd_y*=0.81
 self.spd_x*=0.81
 if (self.t>self.lifetime) del(glb_pwrup_particles,self)
end

function cls_pwrup_particle:draw()
 local col=self.cols[flr(#self.cols*self.t/self.lifetime)+1]
 circfill(self.x,self.y,(2-self.t/self.lifetime*2),col)
end

pwrup_colors={
 {8,2,1},
 {7,6,5},
 {9,8,7,2},
 {6,6,5,1},
 {12,13,2,1},
 {9,8,2,1},
 {11,3,6,1}
}
function make_pwrup_explosion(x,y,explode)
 if (#glb_pwrup_particles>80) return

 local radius=20
 local off=mrnd(1)
 local cols=rnd_elt(pwrup_colors)
 local spd_mod=4+mrnd(0.5)
 local inc=0.12+mrnd(0.03)

 for i=0,1,inc do
  local p=cls_pwrup_particle.init(x,y,i+off,cols)
  p.spd_x*=spd_mod
  p.spd_y*=spd_mod
 end

 if explode then
  local radius=14
  add_cr(function ()
   for i=0,1 do
    local r=outexpo(i,radius,-radius,20)
    circfill(x,y,r,cols[1])
    yield()
   end
  end, glb_draw_crs)
 end
end
