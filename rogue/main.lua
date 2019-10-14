
function draw_game()
 cls(0)
 map()
 drw(p)
end

function ani(_spr,l)
 return _spr+(glb_frame/8)%l
end

function drw(obj)
 palt(0,false)
 pal(6,obj.color)
 spr(ani(obj.sprite,4),obj.x*8+obj.ox,obj.y*8+obj.oy,1,1,obj.dir)
 pal()
 tick_crs(draw_crs)
end
