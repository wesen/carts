smoke={
    init=function(this)
        this.spr=29
        this.spd.y=-0.1
        this.spd.x=0.3+rnd(0.2)
        this.x+=-1+rnd(2)
        this.y+=-1+rnd(2)
        this.flip.x=maybe()
        this.flip.y=maybe()
        this.solids=false
    end,
    update=function(this)
        this.spr+=0.2
        if this.spr>=32 then
            destroy_object(this)
        end
    end
}