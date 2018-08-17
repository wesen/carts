pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--helpers

function class (init)
  local c = {}
  c.__index = c
  c._ctr=init
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    self.destroyed=false
    return self
  end
  c.destroy=function(self)
   self.destroyed=true
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,parent)
end

-- misc helpers
function round(x)
 if (x%1)<0.5 then
  return flr(x)
 else
  return ceil(x)
 end
end

--
local objs=class(function(self)
 self.objs={}
end)

function objs:add(obj)
 add(self.objs,obj)
end

function objs:del(obj)
 del(self.objs,obj)
 obj:destroy()
end

function objs:clear()
 for o in all(self.objs) do
  self:del(o)
 end
end

function objs:update()
 for obj in all(self.objs) do
  obj:update()
 end
end

function objs:draw()
 for obj in all(self.objs) do
  obj:draw()
 end
end

-- coroutines
crs={}

function tick_crs()
 for cr in all(crs) do
  if costatus(cr)!='dead' then
   coresume(cr)
  else
   del(crs, cr)
  end
 end
end

function add_cr(f)
 local cr=cocreate(f)
 add(crs,cr)
 return cr
end

function wait_for_cr(cr)
 if (cr==nil) return
 while costatus(cr)!='dead' do
  yield()
 end
end

function wait_for_crs(crs)
 local all_done=false
 while not all_done do
  all_done=true
  for cr in all(crs) do
   if costatus(cr)!='dead' then
    all_done=false
    break
   end
  end
 end
end

function run_sub_cr(f)
 wait_for_cr(add_cr(f))
end

-- tweens
--- function for calculating 
-- exponents to a higher degree
-- of accuracy than using the
-- ^ operator.
-- function created by samhocevar.
-- source: https://www.lexaloffle.com/bbs/?tid=27864
-- @param x number to apply exponent to.
-- @param a exponent to apply.
-- @return the result of the 
-- calculation.
function pow(x,a)
  if (a==0) return 1
  if (a<0) x,a=1/x,-a
  local ret,a0,xn=1,flr(a),x
  a-=a0
  while a0>=1 do
      if (a0%2>=1) ret*=xn
      xn,a0=xn*xn,shr(a0,1)
  end
  while a>0 do
      while a<1 do x,a=sqrt(x),a+a end
      ret,a=ret*x,a-1
  end
  return ret
end

function inoutquint(t, b, c, d)
  t = t / d * 2
  if (t < 1) return c / 2 * pow(t, 5) + b
  return c / 2 * (pow(t - 2, 5) + 2) + b
end

function inexpo(t, b, c, d)
  if (t == 0) return b
  return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end

function outexpo(t, b, c, d)
  if (t == d) return b + c
  return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end

function inoutexpo(t, b, c, d)
  if (t == 0) return b
  if (t == d) return b + c
  t = t / d * 2
  if (t < 1) return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
  return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end

function wait_for(d,cb)
 local end_time=time()+d
 wait_for_cr(add_cr(function()
  while time()<end_time do
   yield()
  end
  if (cb!=nil) cb()
 end))
end

function animate(obj,sprs,d,loop,cb)
 return add_cr(function()
  repeat 
   for s in all(sprs) do
    obj.spr=s
    wait_for(d)
   end
  until (not loop) or obj.destroyed
  cb()
 end)
end

function move_to(obj,x,y,d,easetype)
 local timeelapsed=0
 local bx=obj.x
 local cx=x-bx
 local by=obj.y
 local cy=y-by
 return add_cr(function()
  while timeelapsed<d do
   timeelapsed+=dt
   if (timeelapsed>d) return
   obj.x=round(easetype(timeelapsed,bx,cx,d))
   obj.y=round(easetype(timeelapsed,by,cy,d))
   yield() 
  end
 end)
end

-- vectors
local v2mt={}
v2mt.__index=v2mt

function v2(x,y)
 local t={x=x,y=y}
 return setmetatable(t,v2mt)
end

function v2mt.__add(a,b)
 return v2(a.x+b.x,a.y+b.y)
end

function v2mt.__sub(a,b)
 return v2(a.x-b.x,a.y-b.y)
end

function v2mt.__mul(a,b)
 if (type(a)=="number") return v2(b.x*a,b.y*a)
 if (type(b)=="number") return v2(a.x*b,a.y*b)
 return v2(a.x*b.x,a.y*b.y)
end

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
end

local bboxvt={}
bboxvt.__index=bboxvt

function bbox(aa,bb)
 return setmetatable({aa=aa,bb=bb},bboxvt)
end

function bboxvt:w()
 return self.bb.x-self.aa.x
end

function bboxvt:h()
 return self.bb.y-self.aa.y
end

function bboxvt:is_inside(v)
 return v.x>=self.aa.x 
    and v.x<=self.bb.x  
    and v.y>=self.aa.y
    and v.y<=self.bb.y        
end

function bboxvt:str()
 return self.aa:str().."-"..self.bb:str()
end
-->8
-- classes

-- constants
dir_left={-1,0}
i_dir_left=1
dir_right={1,0}
i_dir_right=2
dir_up={0,-1}
dir_upright={1,-1}
dir_upleft={-1,-1}
i_dir_up=3
dir_down={0,1}
dir_downright={1,1}
dir_downleft={-1,1}
i_dir_down=4
directions={dir_left,dir_right,dir_up,dir_down}
directions_180={i_dir_right,i_dir_left,i_dir_down,i_dir_up}
death_directions={dir_downleft,dir_downright,dir_upright,dir_downright}

function rotate_180(direction)
 return directions_180[direction]
end

player_spr=64
dead_player_spr=69
sentry_spr=80
patroling_spr=96
arrow_spr=5
card_spr=7
marker_spr=48
background_spr=9

shake=0

function v_idx(x,y) 
 return y*16+x
end

function idx_v(v)
 return {v%16,flr(v/16)}
end

-- globals
init_animation_speed=0.01

-- node
class_node=class(function(self,x,y)
 self.x=x
 self.y=y
 self.spr=15
 self.is_goal=false
 self.initialized=false
end)

function class_node:str()
 return "n:"..tostr(self.x)..","..tostr(self.y)
end

-- xxx this should be a cr
function class_node:initialize()
 if (self.initialized) return
 local sprs={16,17,18,19}
  self.initialized=true
 if (self.is_goal) sprs[4]=20
 animate(self,sprs,init_animation_speed,false,function()
  for n in all(board:get_neighbors(self.x,self.y)) do
   local f=function()
    n:initialize()
   end
   if (n.x < self.x) board.links[v_idx(self.x-1,self.y)]:initialize(true,f)
   if (n.x > self.x) board.links[v_idx(self.x+1,self.y)]:initialize(false,f)
   if (n.y < self.y) board.links[v_idx(self.x,self.y-1)]:initialize(false,f)
   if (n.y > self.y) board.links[v_idx(self.x,self.y+1)]:initialize(true,f)
   if (self.is_goal) animate(self,{20,20,20,20,22,22,22,22,21},0.1,true)
  end
 end)
end

-- link
class_link=class(function(self,x,y,is_v)
 self.x=x
 self.y=y
 self.is_v=is_v
 self.spr=15
 self.initialized=false
end)

function class_link:initialize(flip_spr,cb)
 if (self.initialized) return
 self.initialized=true
 self.flip_spr=flip_spr
 local sprs={32,33,34,35}
 if (self.is_v) sprs={36,37,38,39}
 animate(self,sprs,init_animation_speed,false,cb)
end

-- levels
levels={}
meta_level=bbox(v2(112,0),v2(123,3))

function load_levels()
 for mx=0,128 do
  for my=0,128 do
   if not meta_level:is_inside(v2(mx,my)) then
    local m=mget(mx,my)
    if band(fget(m),128)==128 then
     local level=m-marker_spr+1
     if levels[level]==nil then
      levels[level]=bbox(v2(mx,my),nil)
     else
      local l=levels[level]
      if (mx>l.aa.x) or (my>l.aa.y) then
       l.bb=v2(mx,my+1)
       l.aa.x+=1
      else
       l.bb=v2(l.aa.x,l.aa.y+1)
       l.aa=v2(mx+1,my)
      end
       printh("result "..l:str())
     end
    end
   end
  end
 end
-- levels[1]=bbox(v2(0,0),v2(6,5))
-- levels[2]=bbox(v2(1,15),v2(12,24))
-- levels[3]=bbox(v2(1,15),v2(12,24))
 printh("found "..tostr(#levels).." levels")
end


--board
class_board=class(function(self,bbox)
 self.nodes={}
 self.is_metalevel=bbox==meta_level
 self.links={}
 self.bbox=bbox
 printh("load level "..bbox:str())
 for mx=bbox.aa.x,bbox.bb.x-1 do
  for my=bbox.aa.y,bbox.bb.y-1 do
   local m=mget(mx,my)
   local x=mx-bbox.aa.x
   local y=my-bbox.aa.y
   local f=fget(m)
   local v=v_idx(x,y)
   if band(f,1)==1 then
    -- node
    local n=class_node.init(x,y)
    self.nodes[v]=n
    if band(f,4)==4 then
     if (self.start_node==nil) self.start_node=n
    end
    if band(f,2)==2 then
     self.goal=n
     n.is_goal=true
    end
    if band(f,128)==128 then
     n.level=mget(self.bbox.aa.x+n.x,self.bbox.aa.y+n.y)-marker_spr+1
     printh("set node "..n:str().." to level "..tostr(n.level))
     if n.level==game.current_level then
      self.start_node=n
      printh("set start node to "..n:str())
     end
    end
    if band(f,8)==8 then
     enemies:add(class_enemy.init(n,m))
    end
   elseif band(f,16)==16 then
    self.links[v]=class_link.init(x,y,false)
   elseif band(f,32)==32 then
    self.links[v]=class_link.init(x,y,true)
   end
  end
 end
 
 self.start_node:initialize()
end)

function class_board:destroy()
 for n in all(self.nodes) do
  n:destroy()
 end
 enemies:clear()
 for l in all(self.links) do
  l:destroy()
 end
 self.nodes={}
 self.links={}
 self.destroyed=true
end

function class_board:get_spr(node)
 return mget(self.bbox.aa.x+node.x,self.bbox.aa.y+node.y)
end

function class_board:has_link(node,direction)
 local v=v_idx(node.x+direction[1],node.y+direction[2])
 return board.links[v] != nil
end

function class_board:get_node_in_direction(node,direction)
 if self:has_link(node,direction) then
  local v=v_idx(node.x+direction[1]*2,node.y+direction[2]*2)
  return self.nodes[v]
 end
end

function class_board:get_enemies_in_direction(node,direction)
 local node=self:get_node_in_direction(node,direction)
 local res={}
 for enemy in all(enemies.objs) do
  if (enemy.node==node) add(res,enemy)
 end
 return res
end

function class_board:get_neighbors(x,y)
 local res={}
 if (self.links[v_idx(x-1,y)]!=nil) add(res,self.nodes[v_idx(x-2,y)])
 if (self.links[v_idx(x+1,y)]!=nil) add(res,self.nodes[v_idx(x+2,y)])
 if (self.links[v_idx(x,y-1)]!=nil) add(res,self.nodes[v_idx(x,y-2)])
 if (self.links[v_idx(x,y+1)]!=nil) add(res,self.nodes[v_idx(x,y+2)])
 return res
end

function class_board:draw()
 map(self.bbox.aa.x,self.bbox.aa.y,
     0,0,self.bbox:w(),self.bbox:h())
 palt(0,false)
 for v,n in pairs(self.nodes) do
  spr(background_spr,n.x*8,n.y*8)
 end
 for v,n in pairs(self.links) do
  spr(background_spr,n.x*8,n.y*8)
 end
 palt()
 for v,n in pairs(self.nodes) do
  if self.is_metalevel and n!=board.start_node and n!=board.goal then
   local col=n.level
--   printh("drawing node "..n:str().." level "..tostr(n.level))
   if (n.level==nil) col=6
   pal(6,col)
   spr(n.spr,n.x*8,n.y*8)
   pal(6,6)
  else
   spr(n.spr,n.x*8,n.y*8)
  end
 end
 for v,l in pairs(self.links) do  
  local flip_v=not (l.is_v and l.flip_spr)
  local flip_h=(not l.is_v) and l.flip_spr
  spr(l.spr,l.x*8,l.y*8,1,1,flip_h,flip_v)
 end
end

-->8
-- player and enemies

-- arrows
arrow_animation_speed=0.3

class_arrow=class(function(self,direction)
 self.visible=false
 self.offset=0
 self.direction=direction
 
 add_cr(function() 
  while true do
   wait_for(arrow_animation_speed)
   self.offset=(self.offset+1)%3
  end
 end)
end)

function class_arrow:draw()
 if self.visible then
  if self.direction==dir_left then
   spr(arrow_spr,
       (player.node.x-1)*8-self.offset,
       player.node.y*8,
       1,1,true,false)
  elseif self.direction==dir_right then
   spr(arrow_spr,
       (player.node.x+1)*8+self.offset,
       player.node.y*8,
       1,1,false,false)
  elseif self.direction==dir_up then
   spr(arrow_spr+1,
       player.node.x*8,
       (player.node.y-1)*8-self.offset,
       1,1,false,true)
  else
   spr(arrow_spr+1,
       player.node.x*8,
       (player.node.y+1)*8+self.offset,
       1,1,false,false)
  end
 end  
end

arrows=objs.init("arrows")

function arrows:hide()
 foreach(self.objs,function(arr)
  arr.visible=false
 end)
end

function arrows:show()
 foreach(self.objs,function(arr)
  if not arr.visible then
   arr.offset=0
   arr.visible=true
  end
 end)
end

arrows:add(class_arrow.init(dir_left))
arrows:add(class_arrow.init(dir_right))
arrows:add(class_arrow.init(dir_up))
arrows:add(class_arrow.init(dir_down))

-- mover
class_mover=class(function(self,node,map_spr)
 self.node=node
 self.spr=map_spr
 self.start_spr=self.spr-(self.spr%4)
 self.is_moving=false
 self.has_finished_turn=false
 -- draw offsets
 self.x=0
 self.y=0
 self.direction=self.spr-self.start_spr+1
end)

function class_mover:move(i)
 local direction=directions[i]
 local node=board:get_node_in_direction(self.node,direction)
 if node!=nil then
  local cr=add_cr(function()
   self.is_moving=true
   self.direction=i
   wait_for_cr(move_to(self,direction[1]*16,direction[2]*16,1,outexpo))
   self.x=0
   self.y=0   
   self.node=node
   self.is_moving=false
  end) 
  return cr
 end
end

function class_mover:draw()
 if (is_blink) return
 if self.is_dead then
  local v=death_directions[self.death_direction]
  spr(self.start_spr+5,
      (self.node.x+v[1])*8,
      (self.node.y+v[2])*8)
 else
  spr(self.start_spr+self.direction-1,self.node.x*8+round(self.x),self.node.y*8+round(self.y))
 end
end

function class_mover:die(direction)
 return add_cr(function()
  make_explosion(v2(self.node.x*8+4,self.node.y*8+4))
  shake=.2
  wait_for(0.2)
  self.is_dead=true
  self.death_direction=direction
 end)
end

-- player
class_player=subclass(class_mover,
function(self)
 class_mover._ctr(self,board.start_node,board:get_spr(board.start_node))
end)

function class_player:move(i)
 return add_cr(function()
  local cr=class_mover.move(self,i)
  if (cr==nil) return
  local crs={cr}
  local enemies=board:get_enemies_in_direction(self.node,directions[i])
  for enemy in all(enemies) do
   add(crs,add_cr(function()
    wait_for(0.2)
    wait_for_cr(enemy:die(i))
   end))
  end
  wait_for_crs(crs)
  self.has_finished_turn=true
 end)
end

-- only called in the correct states
function class_player:update()
 for i=1,5 do
  if btnp(i-1) and not self.is_moving then
   self:move(i)
   break
  end
 end
 if btnp(4) then
  game:restart_level()
 end
end

-- enemies
enemies=objs.init("enemies")

function enemies:are_enemies_done()
 for enemy in all(self.objs) do
  if (not enemy.has_finished_turn) return false
 end
 
 return true
end

class_enemy=subclass(class_mover,
function(self,node,map_spr)
 class_mover._ctr(self,node,map_spr)
end)

function class_enemy:do_turn()
 if (self.is_dead) then 
  self.has_finished_turn=true
  return
 end
 self.has_finished_turn=false
 return add_cr(function()
  local front_node=board:get_node_in_direction(self.node,directions[self.direction])
  if front_node==player.node then
   local d=self.direction
   printh("player dead")
   -- concurrently
   wait_for_crs({
   add_cr(function()
    wait_for(0.2)
    wait_for_cr(player:die(d))
   end),
   class_mover.move(self,self.direction)
   })
  else
   if self.start_spr==patroling_spr then
    if front_node!=nil then
     wait_for_cr(class_mover.move(self,self.direction))
     printh("enemy move finished")
     if not board:has_link(self.node,directions[self.direction]) then
      self.direction=rotate_180(self.direction)
     end
    end
   elseif self.start_spr==sentry_spr then
   end
  end
  self.has_finished_turn=true
 end)
end

function class_enemy:draw()
 if (self.node.initialized) class_mover.draw(self)
end

-->8
-- todo

--[[
x helper methods
x board graph
x draw graph
x draw graph animations
x player movement
x player movement animation
x player rotation
x don't move while initializing
x player arrows
x goal node
x win condition
x turns
x enemies
x enemy movement
x sense player
x clean up direction handling
x death animation player
x put dead player in direction of blow
x player death ends game
x enemy death
x enemy death smoke
x goal arrows
x handle multiple game levels
x chain levels
x add game state machine
x death animation enemies
x background sprites
x end level cards
x load levels automatically
x start screen
x end screen
x screen shake on death and level
x draw screen fade on end level cards
x select level metalevel
x restart level button
x remember meta level position
x add helper variables to skip states
x display reload icon on game screen
x fix starting node of metalevel
x loop game around
x add finish game screen
x don't enter invalid level in metalevel
- chose to enter level
- only allow completed levels
x display level name on card
x display level name on metalevel
- no kills / all kills status
- define background tile for level
- start screen gfx
- count turns
- dedicated victim to kill at goal
- briefcases
- hiding in plants
- more enemies
  - walker
  - multiple enemies on one spot
  - enemy distractions

- tutorial mode?
- sound fx
- music
- levels

-- refactoring
- refactor player update to cr
- refactor to use v2
]]
-->8
-- game

-- constants and globals
turn_player=0
turn_enemy=1
is_blink=false

state_start_screen=0
state_load_level=1
state_play=2
state_end_screen=3
state_finish_game=4

-- debug flags
dbg_skip_start=false
dbg_skip_metalevel=false
dbg_auto_win=false
dbg_start_level=2
init_animation_speed=0
dbg_draw=false

-- game
class_game=class(function (self)
 self.state=state_start_screen
 self.turn=turn_player
 self.is_metalevel=false
end)

function class_game:is_level_loaded()
 if (self.state==state_play) return true
 for k,n in pairs(board.nodes) do
  if (not n.initialized) return false
 end
 self.state=state_play
 self.turn=turn_player
 return true 
end

function class_game:is_win()
 return player.node==board.goal
end

function class_game:is_lose()
 return player.is_dead
end

function class_game:play_game_loop()
 
 return add_cr(function()
  while true do
   self:play_start_screen()
 
   while true do
    if (self:play_metalevel()) break
    self:play_normal_level() 
   end
   
   self:play_finish_game()
  end
 end)
end

function class_game:play_start_screen()
 self.current_level=dbg_start_level

 if not dbg_skip_start then
  self.state=state_start_screen
  wait_for_cr(fade(true))  
  music(1)
  pal()
  while not (btnp(4) or btnp(5)) do
 	 yield()
 	end
  music(-1,200)
 	sfx(4)
 	printh("start game")
 	blink()
 	wait_for_cr(fade())
 end 	
end

function class_game:play_metalevel()
 if not dbg_skip_metalevel then
  music(0)
  self.is_metalevel=true
  wait_for_cr(self:play_game_level(meta_level))
  if self:is_win() then
   wait_for_cr(fade())
   return true
  end
  music(-1,300)
  sfx(4)
  wait_for(1)
  blink()
  wait_for_cr(fade())
  printh("faded")
  printh("fade back in next level")
 else
  self.current_level=dbg_start_level
 end
 return false
end

function class_game:play_normal_level()
 ::again::
 self.is_metalevel=false
 music(1)
 wait_for_cr(self:play_game_level(levels[self.current_level]))
 wait_for(1)
 blink()
 wait_for_cr(fade())  

 if self:is_win() then
  printh("won")
  self.state=state_end_screen
  pal()
  wait_for_crs({animate_card()})
  while not (btnp(4) or btnp(5)) do
   yield()
  end
  card.visible=false
  wait_for_cr(fade())

  self.current_level=min(self.current_level+1,#levels+1)
  printh("current level is now "..tostr(self.current_level))
 elseif self:is_lose() then
  printh("lost")
  wait_for(.5)
  goto again
 end
end

function class_game:play_finish_game()
 printh("finished game")
 self.state=state_finish_game
 
 wait_for_cr(fade(true))  
 pal()
 while not (btnp(4) or btnp(5)) do
	 yield()
	end
	blink()
	wait_for_cr(fade())
end

function class_game:restart_level()
 if (not self.is_metalevel) self.request_restart=true
end

function class_game:play_game_level(level)

 return add_cr(function()
::again::
  self.initialized=false
  self.request_restart=false
  if (player) player:destroy()
  if (board) board:destroy()
 
  self.state=state_load_level
  board=class_board.init(level)
  player=class_player.init()

  -- hack for metalevel start position
  if player.spr<64 then
   player.spr=65
   player.start_spr=64
   player.direction=i_dir_right
  end
  
  wait_for_cr(fade(true))
   
  printh("playing level "..tostr(level))

  while not self:is_level_loaded() do
   yield()
  end
  printh("level is loaded")
  
  while not (self:is_win() or self:is_lose()) do
   printh("player turn")
   self.turn=turn_player
   player.has_finished_turn=false
   
   arrows:show()
   while not player.has_finished_turn and not self.request_restart do
    if player.is_moving then
     arrows:hide()
    end
    yield()
   end
   
   if (self.request_restart) goto again
   if (dbg_auto_win) player.node=board.goal
   
   arrows:hide()
   printh("finished player turn")   
   if self.is_metalevel then
    self.meta_position=v2(player.node.x,player.node.y)
    local level=player.node.level
    printh("level: "..tostr(level))
    if level<=16 then
	    self.current_level=level
  	  printh("selected level "..tostr(self.current_level))
 	   -- here we need to handle a x input
   	 break
   	end
   end   
   
   if (self:is_win()) break
   
   printh("enemy turn")
   self.turn=turn_enemy
   for enemy in all(enemies.objs) do
    enemy:do_turn()
   end
   while not enemies:are_enemies_done() do
    yield()
   end
  end
 end)
end

function class_game:update()
 if (self.state==state_play and self.turn==turn_player) player:update()
end

-- shake
shakex=0
shakey=0

function doshake()
 shakex=(8-rnd(16))*shake
 shakey=(8-rnd(16))*shake
 
 shake*=0.9
 if (shake<0.1) shake=0
end

function draw_board()
 if board!=nil then
  local w=64-board.bbox:w()*8/2
  local h=64-board.bbox:h()*8/2
  camera(-w+shakex,-h+shakey)
  board:draw()
  enemies:draw()
  player:draw()
  arrows:draw()
  particles:draw() 
  camera(shakex,shakey)
 end
end

function class_game:draw()
 doshake()
 camera(shakex,shakey)
 if self.state==state_start_screen and not is_blink then
  print("picoman go",32,32)
 elseif self.state==state_finish_game and not is_blink then
  print("you won",32,32)
 elseif self.state==state_end_screen then
  -- do screen fade
  draw_card()
 elseif self.state==state_load_level or self.state==state_play then
  if not self.is_metalevel then
   spr(40,110,10)
   print("🅾️",100,12,6)
  else
   if player!=nil and player.node.level!=nil and not is_blink then
    print("level "..tostr(player.node.level+1),52,80)
   end
  end
  draw_board()
 end

 if dbg_draw then
  print("state: "..tostr(self.state),0,123,7) 
 end
end

-->8
-- main functions

particles=objs.init()

board=nil
player=nil
game=class_game.init()

lasttime=time()
dt=0

function _init()
 load_levels()
 game:play_game_loop()
end

function _update60()
 local t=time()
 dt=t-lasttime
 lasttime=t

 tick_crs()
 game:update()
 particles:update() 
end

function _draw()
 cls()
 game:draw()
end
-->8
-- gfx

smoke_cols={5,6,7,7,10,8}

class_prtcl=class(function(self,pos,d,size)
 self.pos=pos
 -- in pixels per second
 self.d=d
 self.dd=v2(0.9,0.7)
 self.size=size
 self.col=7
 self.life=1
 self.dlife=.5/self.size
end)

function class_prtcl:draw()
  if self.life<.4 or self.life>.7 then
   fillp()
  else
   fillp(0b1010010110100101)
  end
 circfill(self.pos.x,self.pos.y,self.life*self.size,self.col)
end

function class_prtcl:update()
 self.life-=self.dlife
 if self.life<0 then
  particles:del(self)
  return
 end
 self.pos+=(self.d*dt)
 self.d*=self.dd
 local idx=ceil(self.life*#smoke_cols)
 self.col=smoke_cols[idx]
end

function angle2vec(angle)
 return v2(cos(angle),sin(angle))
end

function make_explosion(pos)
 for i=1,40 do
  local d=angle2vec(rnd(1))
  d*=v2(rnd(30)+20,rnd(30)+20)
  d*=v2(2,2)
  local p=class_prtcl.init(pos,d,1+rnd(4))
  particles:add(p)
 end
 for i=1,10 do
  local d=angle2vec(rnd(1))
  d*=v2(rnd(10)+20,rnd(10)+20)
  d*=v2(2,2)
  local p=class_prtcl.init(pos,d,2+rnd(5))
  particles:add(p)
 end
end

-- level card
card={x=-100,y=-40,visible=false}

function animate_card()
 return add_cr(function()
  card.x=-100
  card.y=-40
  card.visible=true
  wait_for_cr(move_to(card,0,0,1,inoutexpo))
 end)
end

function draw_card()
 if (not card.visible) return
 local w=50
 local h=75
 local x1=64-w/2+card.x
 local y1=64-h/2+card.y
 local x2=64+w/2+card.x
 local y2=64+h/2+card.y
 rectfill(x1,y1,x2,y2,7)
 rectfill(x1,y1,x2,y1+10,8)
 rectfill(x1+3,y1+2,
          x1+20,y1+10,7)
          
 print("level "..tostr(game.current_level),x1+11,y1+45,0)
 print("complete",x1+11,y1+52,0)
 circfill(x1+w/2,y1+27,12,6)
 spr(card_spr,x1+w/2-4,y1+62)
end

-- fade
dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}

function fade(fade_in)
 return add_cr(function()
  for i=1,10 do
   local i_=i
   if (fade_in==true) i_=10-i
   local p=flr(mid(0,i_/10,1)*100)
  
   for j=1,15 do
    local kmax=(p+(j*1.46))/22
    local col=j
    for k=1,kmax do
     if (col==0) break
     col=dpal[col]
    end
    pal(j,col,1)
   end
   
   wait_for(0.1)
  end
 end)
end

function blink()
 local blink_speed=0.2
 is_blink=true
 wait_for(blink_speed)
 is_blink=false
 wait_for(blink_speed)
 is_blink=true
 wait_for(blink_speed)
 is_blink=false
 wait_for(.2)
end
__gfx__
00000000909090900000000000090000999999990000000000ddd000008888003333333300000000505050500000000000000000000000000000000000000000
000000000000000900000000000900009000000900000000000d0000088888803333333300050000050505050000000000000000000000000000000000000000
0070070090000000000000000009000090000009d000000000000000887878883333333300000000505050500000000000000000000000000000000000000000
0007700000000009000000000009000090000009dd00000000000000888787883333333300000000050505050000000000000000000000000000000000000000
0007700090000000999999990009000090000009d000000000000000887878883333333300000000505050500000000000000000000000000000000000000000
00700700000000090000000000090000900000090000000000000000888788883333333300000500050505050000000000000000000000000000000000000000
00000000900000000000000000090000900000090000000000000000088888803333333305000000505050500000000000000000000000000000000000000000
00000000090909090000000000090000999999990000000000000000008888003333333300000000050505050000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000bff00000b0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000088000000550003b03b5b03b03b0b0000000000000000000000000000000000000000000000000
000000000000000000006000000000000000000000088000000000000666666003b3353003b33330000000000000000000000000000000000000000000000000
00060000000600000060000000066000000880000088880008088080066666600033595600330900000000000000000000000000000000000000000000000000
00000000000660000000060000066000000880000088880008088080066666600b3993b60b3993b0000000000000000000000000000000000000000000000000
00000000000000000006000000000000000000000008800000000000055555500002250600022000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000088000000000000004400000044000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000600000006000000060000000600000055550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000006000000060000000600000557755000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000060000000600005575575500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600005755565500000000000000000000000000000000000000000000000000000000
60000000660000006660000066666666000000000000000000000000000600005755777500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600005575575500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600000557555000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600000055550000000000000000000000000000000000000000000000000000000000
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
08000080180000812800008238000083480000845800008568000086780000878800008898000089a800008ab800008bc800008cd800008de800008ef800008f
00800800108008012080080230800803408008045080080560800806708008078080080890800809a080080ab080080bc080080cd080080de080080ef080080f
00088000100880012008800230088003400880045008800560088006700880078008800890088009a008800ab008800bc008800cd008800de008800ef008800f
00088000100880012008800230088003400880045008800560088006700880078008800890088009a008800ab008800bc008800cd008800de008800ef008800f
00800800108008012080080230800803408008045080080560800806708008078080080890800809a080080ab080080bc080080cd080080de080080ef080080f
08000080180000812800008238000083480000845800008568000086780000878800008898000089a800008ab800008bc800008cd800008de800008ef800008f
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
00000000000000000000006000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000
66f5500000055f000000006000000000000000000f50f882000000000000000000055f0000000000000000000000000000000000000000000000000000000000
00015500005510000f0000f000555500000000000001f98800000000000000000055100000000000000000000000000000000000000000000000000000000000
000f55000055f000051ff15005555550000000001555588000000000000000000055f00000000000000000000000000000000000000000000000000000000000
000f55000055f00005555550051ff150000000000055502000000000000000000055f00000000000000000000000000000000000000000000000000000000000
0001550000551000005555000f0000f0000000000150f00000000000000000000055100000000000000000000000000000000000000000000000000000000000
00f5500000055f6600000000060000000000000001006000000000000000000000055f6600000000000000000000000000000000000000000000000000000000
00000000000000000000000006000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fdd000000ddf000000000000000000000000000fd0f88200000000000000000000000000000000000000000000000000000000000000000000000000000000
0005dd0000dd50000f0000f000dddd00000000000001f48800000000000000000000000000000000000000000000000000000000000000000000000000000000
0004dd0000dd40000d5445d00dddddd0000000005dddd88000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004dd0000dd40000dddddd00d5445d00000000000ddd02000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005dd0000dd500000dddd000f0000f00000000005d0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fdd000000ddf000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fee000000eef000000000000000000000000000fe0f88200000000000000000ffcc00000000000000000000000000000000000000000000000000000000000
0005ee0000ee50000f0000f000eeee00000000000002f488000000000000000005cc7c0000000000000000000000000000000000000000000000000000000000
000aee0000eea0000e5aa5e00eeeeee0000000005eeee8800000000000000000007ffc0000000000000000000000000000000000000000000000000000000000
000aee0000eea0000eeeeee00e5aa5e00000000000eee0200000000000000000007ffc0000000000000000000000000000000000000000000000000000000000
0005ee0000ee500000eeee000f0000f00000000005e0f000000000000000000005cc7c0000000000000000000000000000000000000000000000000000000000
00fee000000eef000000000000000000000000000500000000000000000000000ffcc00000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f9900000099f000000000000000000000000000f90f88200000000000000000000000000000000000000000000000000000000000000000000000000000000
00059900009950000f0000f000999900000000000002f58800000000000000000000000000000000000000000000000000000000000000000000000000000000
000a99000099a000095aa59009999990000000005999988000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a99000099a0000999999009155190000000000099902000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005990000995000009999000f0000f0000000000590f00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f9900000099f000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001c1c000000000000000000000000000000001c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c08080808080800000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001c1c000000000000000000000000000000001c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c08080808080800000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000080808000000000000001c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000080808000000000000001c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000080808080808080808080808081c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080808080808080808080808080808080808080808080808080808081c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080808080808080808080808080808080808080808080808080808081c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808080808080808080808080808080808081c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808080808080808080808080808080808081c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808080808080808080808080808080808081c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000
00000000000000000000050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000
00000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000
00000000000000000000050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000
00000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000
0000000000000000000005050505050d050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000
000000000000000000005050505050ddd05050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000
00000000000000000000050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000
00000000000000000000505050500000000000000000000000000000000000000000000000000000000000000000000000005050505000000000000000000000
000000000000000000000505050500055f0000050000000500000005000000050000000500000005000000050000000500000505050500000000000000000000
00000000000000000000505050d0005510000d000000000000000000000000000000000000000000000000000000000880005050505000000000000000000000
0000000000000000000005050dd50055f0006dd66666000660006666666600011000666666660002200066666666008888000505050500000000000000000000
00000000000000000000505050d00055f0000d000000000660000000000000011000000000000002200000000000008888005050505000000000000000000000
00000000000000000000050505050055150000000500000005000000050000000500000005000000050000000500000885000505050500000000000000000000
000000000000000000005050505005055f6605000000050000000500000005000000050000000500000005000000050000005050505000000000000000000000
00000000000000000000050505050000000000000000000000000000000000000000000000000000000000000000000000000505050500000000000000000000
00000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000
000000000000000000000505050505ddd50505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000
0000000000000000000050505050505d505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000
00000000000000000000050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000
00000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000
00000000000000000000050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000
00000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000
00000000000000000000050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001102003000000000000000000000001010101030101010100000000000000101010102020202000000000000000008181818181818181818181818181818105050505000400000500000000000000090909090008000000000000000000000909090900080000090000000000000009090909000800000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3008080808080a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0000000000
0a08430808080a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4123302331233223140a0000000000
0a08270808080a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0000000000
0a08512314080a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a08080808083000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3108080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008412313235123140800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008080808080808080831000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c1c1c1c1c1c1c1c1c100000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c1c1c1c1c1c1c1c1c100000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c1c1c1c1c1c1c1c1c100000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c1c1c1c1c1c1c1c1c100000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c1c1c1c1c1c1c1c1c100000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c1c1c1c1c1c1c1c1c100000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
320808080808080808080808c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000843080808630808080808c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000827080808270808080808c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000851231323132313231308c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c180808080808080808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000808082708080827080808c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1808080808080808080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000813231323132314080808c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1808080808080808080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080808270827080808080800000000c1c1c1c1c1c1c1c1c1c1c1c1808080808080808080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00085123132362080808080800000000c1c1c1c1c1c1c1c1c1c1c1c1808080808080808080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080808080808080808080832000000c1c1c1c1c1c1c1c1c1c1c1c1808080808080808080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1808080808080808080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1808080808080808080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1808080808080808080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c18080808080c1c1c1c1c1c1c1c1c1c1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000c1c1c1c1c1c1c1c1c1808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000c1c1c1c1c1c1c1c1c1808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000c1c100000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c18080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000c1c100000000000000000000000000000000c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c18080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100200005001050000500105000050010500005001050000500105000050010500005001050000500105000050010500005001050000500105000050010500005001050000500105000050010500005001050
011000000c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e8500c8500e850
0110000018034180301803018030180301802018020180101d0341d0301d0301d0301d0201d0201d0301d0101a0341a0301a0301a0301a0201a0201a0201a0100000000000000000000000000000000000000000
011000001b0541b0501b0501b0401b0301b0301b0201b02022054220502204022040220402204022030220301d0541d0501d0401d0401d0401d0301d0301d0300000000000000000000000000000000000000000
010600000000016055180551b0551f055220552405527055270002e04222022220152e0002e000000002e0002e0002e0050000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 01424344
03 01020344

