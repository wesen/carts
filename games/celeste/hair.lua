function create_hair(obj)
    obj.hair={}
    for i=0,4 do
        add(obj.hair,{x=obj.x,y=obj.y,size=max(1,min(2,3-i))})
    end
end

function set_hair_color(djump)
    pal(8,(djump==1 and 8 or djump==2 and (7+flr((frames/3)%2)*4) or 12))
end

function draw_hair(obj,facing)
    local last={
        x=obj.x+4-facing*2,
        y=obj.y+(btn(k_down) and 4 or 3)
    }

    foreach(obj.hair,function(h)
        -- trailing previous hair
        -- change this from 1.5 to 10 to show slow trailing hair
        h.x+=(last.x-h.x)/1.5
        h.y+=(last.y+0.5-h.y)/1.5
        circfill(h.x,h.y,h.size,8)
        last=h
    end)
end

function unset_hair_color()
    pal(8,8)
end
