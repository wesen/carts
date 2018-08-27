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

function _update()
 if btnp(5) then
  fadelevel=(fadelevel+1)%7
 end
end

function _draw()
 cls()
 map(0,0,0,0,16,16)
 -- circ(stat(32),stat(33),10,9)

 if fadelevel>0 then
  for i=0,32 do
   for j=0,32 do
    local p=pget(i,j)
    pset(i,j,fadetable[p][fadelevel])
   end
  end
 end
end