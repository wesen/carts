players={}

cls_player=subclass(typ_player,cls_actor,function(self,pos)
    cls_actor._ctr(self,pos)
    -- players are handled separately
    del(actors,self)
    add(players,self)

    self.flip=v2(false,false)
    self.jump_button=cls_button.init(btn_jump)
    self.spr=1
    self.hitbox=hitbox(v2(2,0),v2(4,8))
    self.atk_hitbox=hitbox(v2(1,0),v2(6,4))

    self.prev_input=0
    -- we consider we are on the ground for 12 frames
    self.on_ground_interval=0
end)

function cls_player:smoke(spr,dir)
    cls_smoke.init(self.pos,spr,dir)
end

function cls_player:update()
    -- from celeste's player class
    local input=btn(btn_right) and 1
       or (btn(btn_left) and -1
       or 0)

    self.jump_button:update()

    local maxrun=1
    local accel=0.4
    local decel=0.2

    local on_ground=solid_at(self:bbox(v2(0,1)))
    local on_ice=ice_at(self:bbox(v2(0,1)))
    if on_ground then
        self.on_ground_interval=ground_grace_interval
    elseif self.on_ground_interval>0 then
        self.on_ground_interval-=1
    end
    local on_ground_recently=self.on_ground_interval>0

    if not on_ground then
        accel=0.2
        decel=0.1
    else
        if on_ice then
            accel=0.1
            decel=0.03
        end

        if input!=self.prev_input and input!=0 then
            if on_ice then
                self:smoke(spr_ice_smoke,-input)
            else
                -- smoke when changing directions
                self:smoke(spr_ground_smoke,-input)
            end
        end

        -- add ice smoke when sliding on ice (after releasing input)
        if input==0 and abs(self.spd.x)>0.3 and on_ice
           and (maybe(0.15) or self.prev_input!=0) then
            self:smoke(spr_slide_smoke,-input)
        end
    end
    self.prev_input=input

    -- x movement
    if abs(self.spd.x)>maxrun then
        self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
    elseif input != 0 then
        self.spd.x=appr(self.spd.x,input*maxrun,accel)
    else
        self.spd.x=appr(self.spd.x,0,decel)
    end
    if (self.spd.x!=0) self.flip.x=self.spd.x<0

    -- y movement
    local maxfall=2
    local gravity=0.12

    -- slow down at apex
    if abs(self.spd.y)<=0.15 then
        gravity*=0.5
    elseif self.spd.y>0 then
        -- fall down fas2er
        gravity*=2
    end

    -- wall slide
    local is_wall_sliding=false
    if input!=0 and self:is_solid_at(v2(input,0)) and not on_ground then
        is_wall_sliding=true
        maxfall=0.4
        local smoke_dir = self.flip.x and .3 or -.3
        if (maybe(.1)) self:smoke(spr_wall_smoke,smoke_dir)
    end

    -- jump
    if self.jump_button.is_down then
        if self.jump_button:is_held()
             or (on_ground_recently and self.jump_button:was_recently_pressed()) then
            if self.jump_button:was_recently_pressed() then
                self:smoke(spr_ground_smoke,0)
            end
            self.on_ground_interval=0
            self.spd.y=-1.0
            self.jump_button.hold_time+=1
        elseif self.jump_button:was_just_pressed() then
            -- check for wall jump
            local wall_dir=self:is_solid_at(v2(-3,0)) and -1
                          or self:is_solid_at(v2(3,0)) and 1
                          or 0
            if wall_dir!=0 then
                self.jump_interval=0
                self.spd.y=-1
                self.spd.x=-wall_dir*(maxrun+1)
                self:smoke(spr_wall_smoke,-wall_dir*.3)
                self.jump_button.hold_time+=1
            end
        end
    end

    if (not on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

    self:move(self.spd)

    -- animation
    if input==0 then
        self.spr=1
    elseif is_wall_sliding then
        self.spr=4
    elseif not on_ground then
        self.spr=3
    else
        self.spr=1+flr(frame/4)%3
    end
end

function cls_player:draw()
    spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)

    --[[
    local bbox=self:bbox()
    local bbox_col=8
    if self:is_solid_at(v2(0,0)) then
        bbox_col=9
    end
    bbox:draw(bbox_col)
    bbox=self.atk_hitbox:to_bbox_at(self.pos)
    bbox:draw(12)
    print(self.spd:str(),64,64)
    ]]
end

