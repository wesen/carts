--[[
IDEAS:

- guide moth through a maze using light
- guide moth through a maze / cross platformer to turn on the lights
- shine a flashlight to disperse bugs / critters
]]

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

fadelevel=1

mode_naive=0
mode_peekpoke=1
mode_lookup=2
mode_peeklookup=3

current_mode=0
max_mode=4

function naive_replace()
  for i=0,32 do
   for j=0,32 do
    local p=pget(i,j)
    pset(i,j,fadetable[p+1][fadelevel])
   end
  end
end

lookup_tables={}

function compute_lookup_tables()
 for level=1,5 do
  local table={}
  for p1=0,15 do
   for p2=0,15 do
    local f1=fadetable[p1+1][level]
    local f2=fadetable[p2+1][level]
    table[p1+p2*16]=f1+f2*16
   end
  end
  lookup_tables[level]=table
 end
 lookup_tables[1][0]=23
end

base_addr=0x4300

function store_lookup_tables()
 for level=1,5 do
  local addr=base_addr+0x100*(level-1)
  for i=0,255 do
   poke(addr+i,lookup_tables[level][i])
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
   p1=fadetable[p1+1][fadelevel]
   p2=fadetable[p2+1][fadelevel]
   v=bor(p1,shl(p2,4))
   poke(a,v)
  end
 end
end

function lookup_replace()
 for i=0,32,2 do
  for j=0,32 do
   local a=0x6000+j*0x40+i/2
   poke(a,lookup_tables[fadelevel][peek(a)])
  end
 end
end

function peeklookup_replace()
 local addr=base_addr+0x100*(fadelevel-1)
 for i=0,32,2 do
  for j=0,32 do
   local a=0x6000+j*0x40+i/2
   poke(a,peek(bor(addr,peek(a))))
  end
 end
end

function _init()
 poke(0x5f2d,1)
 compute_lookup_tables()
 store_lookup_tables()
end

function _update()
 if btnp(4) then
  current_mode=(current_mode+1)%max_mode
 end
 if btnp(5) then
  fadelevel=(fadelevel+1)%6
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
  elseif current_mode==mode_lookup then
   lookup_replace()
  elseif current_mode==mode_peeklookup then
   peeklookup_replace()
  end
 end

 rectfill(0,60,128,80,1)
 print("cpu: "..tostr(stat(1)), 0, 64,7)
 if current_mode==mode_naive then
  print("naive",64,64,7)
 elseif current_mode==mode_peekpoke then
  print("peekpoke",64,64,7)
 elseif current_mode==mode_lookup then
  print("lookup",64,64,7)
 elseif current_mode==mode_peeklookup then
  print("peeklookup",64,64,7)
 end
end