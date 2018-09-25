console_lines={}
console_size=15

function clear_console()
 console_lines={}
end

function shift_console()
 if #console_lines>=15 then
  for i=2,15 do
   console_lines[i-1]=console_lines[i]
  end
  for i=15,#console_lines do
   console_lines[i]=nil
  end
 end
end

function cstr(str)
 shift_console()
 console_lines[#console_lines+1]=str
end

function draw_console()
 local i=0
 for _,v in pairs(console_lines) do
  print(console_lines[i],0,i*6)
  i+=1
 end
end
