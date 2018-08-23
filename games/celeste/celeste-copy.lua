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
-- x jump
-- x solidity checks
-- x objects
-- multijumps
-- spawn player
-- platforms
-- dash
-- smoke
-- ice
-- spikes
-- kill player
-- fall floor
-- fake wall

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
        this.was_on_ground=false

        -- solidity checks
        this.hitbox={x=1,y=3,w=6,h=5}

        create_hair(this)
    end,
    update=function(this)
        local input = btn(k_right) and 1 or (btn(k_left) and -1 or 0)

        local on_ground=this.is_solid(0,1)

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

        if not on_ground then
            accel=0.4
        end

        if abs(this.spd.x)>maxrun then
            this.spd.x=appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)
        else
            this.spd.x=appr(this.spd.x,input*maxrun,accel)
        end

        --facing
        if this.spd.x!=0 then
            this.flip.x=(this.spd.x<0)
        end

        -- gravity
        local maxfall=2
        local gravity=0.21

        -- slow fall when getting slower
        if abs(this.spd.y)<=0.15 then
            gravity*=0.5
        end

        -- jump
        if this.jbuffer>0 then
            psfx(1)
            this.jbuffer=0
            this.spd.y=-2
        end

        if not on_ground then
            this.spd.y=appr(this.spd.y,maxfall,gravity)
        end

        -- animation
        this.spr_off+=0.25
        if not on_ground then
            this.spr=3
		elseif (this.spd.x==0) or (not btn(k_left) and not btn(k_right)) then
            this.spr=1
		else
            this.spr=1+this.spr_off%4
        end

        this.was_on_ground=on_ground
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
--#include objects

--#include main-functions
--#include helpers