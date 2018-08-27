--[[
IDEAS:

- guide moth through a maze using light
- guide moth through a maze / cross platformer to turn on the lights
- shine a flashlight to disperse bugs / critters
]]

function _init()
 poke(0x5f2d,1)
end

local fadetable={
 {0,0,0,0,0},
 {1,1,0,0,0},
 {2,2,1,0,0},
 {3,3,1,0,0},
 {4,2,2,0,0},
 {5,1,1,0,0},
 {13,13,5,5,1},
 {6,13,13,5,1},
 {8,2,2,2,0},
 {9,4,4,5,0},
 {10,4,4,5,0},
 {11,3,3,0,0},
 {12,3,1,1,1},
 {13,5,1,1,0},
 {14,4,2,2,0},
 {15,13,5,5,1}
}

fadelevel=0

mode_naive=0
mode_peekpoke=1

current_mode=0

function _update()

 if btnp(4) then
  current_mode=(current_mode+1)%2
 end
 if btnp(5) then
  fadelevel=(fadelevel+1)%7
 end
end

function naive_replace()
  for i=0,32 do
   for j=0,32 do
    local p=pget(i,j)
    pset(i,j,fadetable[p][fadelevel])
   end
  end
end

function poke_replace()
 for i=0,32,2 do
  for j=0,32 do
   local a=0x6000+j*0x40+i/2
   local v=peek(a)
   local p1=band(v,0xf)
   local p2=flr(shr(v,4))
   p1=fadetable[p1][fadelevel]
   p2=fadetable[p2][fadelevel]
   v=bor(p1,shl(p2,4))
   poke(a,v)
  end
 end
end

function _draw()
 cls()
 map(0,0,0,0,16,16)
 -- circ(stat(32),stat(33),10,9)

 if fadelevel>0 then
  if current_mode==mode_naive then
   naive_replace()
  elseif current_mode==mode_peekpoke then
   poke_replace()
  end
 end

 rectfill(0,60,128,80,1)
 print("cpu: "..tostr(stat(1)), 0, 64,7)
 if current_mode==mode_naive then
  print("naive",64,64,7)
 elseif current_mode==mode_peekpoke then
  print("peekpoke",64,64,7)
 end
end