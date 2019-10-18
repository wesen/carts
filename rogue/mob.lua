mobs={}

mob_atk={1,2}
mob_hp={2,2}

function add_mob(typ,mx,my)
  add(mobs,{
    x=mx,y=my,
    typ=typ,
    ox=0,oy=0,
    dir=false,
    sprite=192+4*(typ-1),
    color=8,
    bumped_t=0,
    hp=mob_hp[typ],
    atk=mob_atk[typ]
  })
end

function get_mob(x,y)
  for m in all(mobs) do
    if m.x==x and m.y==y then
      return m
    end
  end
  return false
end

function cr_hit_mob(attacker,defender)
 defender.hp-=attacker.atk
 local x,y=defender.x*8,defender.y*8
 local p=cls_score_particle.init(x,y,tostr(-attacker.atk),0,7)
 p.lifetime=0.4
 defender.should_blink=true
 shake(defender,2)
 shake(attacker,2)
 cr_wait_for(.5)

 printh("defender.hp "..tostr(defender.hp))
 if defender.hp<=0 then
   make_pwrup_explosion(x+4,y+4,true)
   sfx(55)
   del(mobs,defender)
 end

 defender.should_blink=false
end

function draw_mobs()
  drw=function(obj)
    update_shake(obj)
    if obj.should_blink and flr(glb_frame/6)%2==1 then
      pal(6,1)
    else
      pal(6,obj.color)
    end
    spr(ani(obj.sprite,4),obj.x*8+obj.ox+obj.shkx,obj.y*8+obj.oy+obj.shky,1,1,obj.dir)
  end
  palt(0,false)
  foreach(mobs,drw)
  drw(p)
  pal()
end

function cr_mob_turn()
  local mob_crs={}
  for mob in all(mobs) do
    add_cr(mkcr_mob_move(mob,1), mob_crs)
  end
  cr_wait_for_crs(mob_crs)
end

function cb_mob_move(mob,dir,move,bump)
  local flag,tile,tx,ty=get_tile_in_direction(mob,dir)
  if band(flag,1024)==1024 then
    -- mob
    sfx(54)
    cr_hit_mob(mob,p)
  elseif band(flag,1)~=1 then
    move()
  else
    if bump(1) then
      mob.bumped_t=time()
    end
  end
end

function mkcr_mob_move(mob,dir)
  return function()
    cr_move_mob(mob,dir,cb_mob_move)
  end
end
