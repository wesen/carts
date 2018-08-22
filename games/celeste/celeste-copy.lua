-- ~celeste~
-- matt thorson + noel berry

k_left=0
k_right=1
k_up=2
k_down=3
k_jump=4
k_dash=5

-- x first, drawing of the current room
-- x draw terrain
-- x draw player
-- x draw player hair
-- x animate player
-- x move player
-- x draw hair
-- jump
-- dash
-- smoke
-- kill player

max_djump=1
frames=0
seconds=0
minutes=0

sfx_timer=0

-- levels
room={x=0,y=0}

-- player
player={
    init=function(this)
        this.spr_off=0
        this.djump=max_djump

        -- jump
        this.p_jump=false
        this.jbuffer=0

        create_hair(this)
    end,
    update=function(this)
        local input = btn(k_right) and 1 or (btn(k_left) and -1 or 0)

        -- is this the jump transition
        local jump=btn(k_jump) and not this.p_jump
        this.p_jump=btn(k_jump)
        if (jump) then
            this.jbuffer=4
        elseif this.jbuffer>0 then
            this.jbuffer-=1
        end

        local maxrun=1
        local accel=0.6
        local deccel=0.15

        if abs(this.spd.x) > maxrun then
            this.spd.x=appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)
        else
            this.spd.x=appr(this.spd.x,input*maxrun,accel)
        end

        --facing
        if this.spd.x!=0 then
            this.flip.x=(this.spd.x<0)
        end

        -- jump
        if this.jbuffer>0 then
            psfx(1)
            this.jbuffer=0
            this.spd.y=-2
        end

        -- animation
        this.spr_off+=0.25
		if (this.spd.x==0) or (not btn(k_left) and not btn(k_right)) then
			this.spr=1
		else
			this.spr=1+this.spr_off%4
		end
    end,
    draw=function(this)
        if this.x<-1 or this.x>121 then
            this.x=clamp(this.x,-1,121)
			this.spd.x=0
        end

        this.djump=1
        set_hair_color(this.djump)
        draw_hair(this,this.flip.x and -1 or 1)
        spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
        unset_hair_color()
    end
}

--#include hair

function move(obj,ox,oy)
    local amount

    -- compute fractional moves
    obj.rem.x+=ox
    amount=flr(obj.rem.x+0.5)
    obj.rem.x-=amount
    move_x(obj,amount,0)

    obj.rem.y+=oy
    amount=flr(obj.rem.y+0.5)
    obj.rem.y-=amount
    move_y(obj,amount)
end

function move_x(obj,amount,start)
    -- move in small steps to check for solids later on
    local step=sign(amount)
    for i=start,abs(amount) do
        obj.x+=step
    end
end

function move_y(obj,amount)
    local step=sign(amount)
    for i=0,abs(amount) do
        obj.y+=step
    end
end

-- helper functions
flg_solid=0
flg_ice=4

function solid_at(x,y,w,h)
    return tile_flag_at(x,y,w,h,flg_solid)
end

function ice_at(x,y,w,h)
    return tile_flag_at(x,y,w,h,flg_ice)
end

function tile_at(x,y)
    -- wsn why 16? because rooms are 16x16
    return mget(room.x*16+x,room.y*16+y)
end

function tile_flag_at(x,y,w,h,flag)
    for i=max(0,flr(x/8)),min(15,(x+w-1)/8) do
        for j=max(0,flr(y/8)),min(15,(y+h-1)/8) do
            if fget(tile_at(i,j),flag) then
                return true
            end
        end
    end
    return false
end

_player={
    type=player,
    x=1*8,
    y=12*8,
    flip={x=false,y=false},
    spd={x=0,y=0},
    rem={x=0,y=0},
    spr=1
}

--#include main-functions
--#include helpers