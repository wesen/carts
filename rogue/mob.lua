mobs={}

mob_atk={1,2}
mob_hp={2,2}

function add_mob(typ,mx,my)
  add(mobs,{
    x=mx,y=my,
    typ=typ,
    ox=0,oy=0,
    dir=false,
    sprite=192+4*typ,
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

function hit_mob(attacker,defender)
 defender.hp-=attacker.atk
end

function draw_mobs()
  drw=function(obj)
    pal(6,obj.color)
    spr(ani(obj.sprite,4),obj.x*8+obj.ox,obj.y*8+obj.oy,1,1,obj.dir)
  end
  palt(0,false)
  foreach(mobs,drw)
  drw(p)
  pal()
end

function cb_mob_move(mob,dir,move,bump)
  local flag,tile,tx,ty=get_tile_in_direction(mob,dir)
  if band(flag,512)==512 then
    -- mob
    hit_mob(tile,mob)
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
