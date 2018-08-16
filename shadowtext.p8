pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function cprint(str,y,col,shadowcol)
 sprint(str,64-#str*2,y,col,shadowcol)
end

function sprint(str,x,y,col,col2)
 print(str,x,y+1,col2)
 print(str,x,y,col)
end

cls()
cprint("foobar",64,10,2)

cprint("foobar",80,7,5)

