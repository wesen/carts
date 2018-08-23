objects={}

function draw_object(obj)
    if obj.type.draw~=nil then
        obj.type.draw(obj)
    elseif obj.spr>0 then
        spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
    end
end

function init_object(type,x,y)
    local obj={}
    obj.type=type
    obj.collideable=true
    obj.solids=true

    obj.spr=type.tile
    obj.flip={x=false,y=false}
    obj.x=x
    obj.y=y
    obj.hitbox={x=0,y=0,w=8,h=8}
    obj.spd={x=0,y=0}
    obj.rem={x=0,y=0}

    obj.is_solid=function(ox,oy)
        return solid_at(obj.x+obj.hitbox.x+ox,
                        obj.y+obj.hitbox.y+oy,
                        obj.hitbox.w,obj.hitbox.h)
    end

    obj.move=function(ox,oy)
        local amount

        -- compute fractional moves
        obj.rem.x+=ox
        amount=flr(obj.rem.x+0.5)
        obj.rem.x-=amount
        obj.move_x(amount,0)

        obj.rem.y+=oy
        amount=flr(obj.rem.y+0.5)
        obj.rem.y-=amount
        obj.move_y(amount)
    end

    obj.move_x=function(amount,start)
        if obj.solids then
            -- move in small steps to check for solids later on
            local step=sign(amount)
            for i=start,abs(amount) do
                if not obj.is_solid(step,0) then
                    obj.x+=step
                else
                    obj.spd.x=0
                    obj.rem.x=0
                    break
                end
            end
        else
            obj.x+=amount
        end
    end

    obj.move_y=function(amount)
        if obj.solids then
            local step=sign(amount)
            for i=0,abs(amount) do
                if not obj.is_solid(0,step) then
                    obj.y+=step
                else
                    obj.spd.y=0
                    obj.rem.y=0
                    break
                end
            end
        else
            obj.y+=amount
        end
    end

    add(objects,obj)
    if obj.type.init~=nil then
        obj.type.init(obj)
    end

    return obj
end

function destroy_object(obj)
    del(objects,obj)
end

