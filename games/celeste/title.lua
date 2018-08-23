function title_screen()
    frames=0
    seconds=0
    minutes=0
    start_game=false
    start_game_flash=0
    max_djump=1
    load_room(7,3)
end

room_title={
    init=function(this)
        this.delay=5
    end,
    draw=function(this)
        this.delay-=1
        if this.delay<-30 then
            destroy_object(this)
        elseif this.delay<0 then
            rectfill(24,58,104,70,0)
            if room.x==3 and room.y==1 then
                print("old side",48,62,7)
            elseif level_index()==30 then
                print("summit",52,62,7)
            else
                local level=(1+level_index())*100
                print(level.." m",52+(level<1000 and 2 or 0),62,7)
            end

            draw_time(4,4)
        end
    end
}

function draw_time(x,y)
    local s=seconds
    local m=minutes%60
    local h=flr(minutes/60)

    rectfill(x,y,x+32,y+6,0)
    print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s),x+1,y+1,7)
end