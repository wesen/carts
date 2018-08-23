
-- helpers
function clamp(val,a,b)
    return max(a,min(b,val))
end

function appr(val,target,amount)
    return (val>target and max(val-amount,target))
      or min(val+amount,target)
end

function sign(v)
    return v>0 and 1 or v<0 and -1 or 0
end

function maybe()
    return rnd(1)<0.5
end

-- this is used to block out sound effects on important sfx
function psfx(num)
    if sfx_timer<=0 then
        sfx(num)
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
