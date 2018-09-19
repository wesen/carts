drop_min_time=60*4
drop_max_time=60*10
max_count=10
power_up_droppers={}

cls_pwrup_dropper=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 -- set spawn time between min time and max time
 self.time=0
 self.item=nil
 self.interval=1
 add(power_up_droppers,self)
end)

local pwrup_counts=0

function cls_pwrup_dropper:update()
 if self.item==nil then
  -- increment time. spawn when time's up
  self.time=(self.time%(self.interval))+1
  if self.time>=self.interval then
   if pwrup_counts<max_count then
    local spr_idx=power_up_tiles[flr(rnd(#power_up_tiles))+1]
    self.item=tiles[spr_idx].init(v2(self.x,self.y))
    self.item.tile=spr_idx
    pwrup_counts+=1
   end
   self.interval=flr(drop_min_time+(rnd(1)*(drop_max_time-drop_min_time)))
  end

 else

  -- check that item has been used before allowing another drop
  local exists=false
  for interactable in all(interactables) do
   if interactable==self.item then
    exists=true
   end
  end

  if not exists then
   pwrup_counts-=1
   self.item=nil
   self.interval=flr(drop_min_time+(rnd(1)*(drop_max_time-drop_min_time)))
   if pwrup_counts<max_count then
    for dropper in all(power_up_droppers) do
     dropper.time=0
    end
   end
  end
 end
end

spr_pwrup_dropper=25
tiles[spr_pwrup_dropper]=cls_pwrup_dropper
