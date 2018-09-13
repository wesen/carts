spr_power_up=39
pwrup_drop_interval=60*10


cls_pwrup_dropper=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.time=0
 self.item=nil
end)

function cls_pwrup_dropper:update()
 if self.item==nil then

  -- Increment time. Spawn when time's up
  self.time=(self.time%(pwrup_drop_interval))+1
  if self.time==pwrup_drop_interval then
   self.item=rnd_elt(pwrups).init(self.pos)
  end

 else

  -- Check that item has been used before allowing another drop
  local exists=false
  for actor in all(actors) do
   if actor==self.item then
    exists=true
   end
  end

  if not exists then
   self.item=nil
  end

 end
end


cls_pwrup=subclass(cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
end)

function cls_pwrup:update()
 local bb=self:bbox()
 for player in all(players) do
  if player:bbox():collide(bb) then
   self:act_on_player(player)
   del(actors,self)
   return
  end
 end
end

function cls_pwrup:act_on_player(player)
end

function cls_pwrup:draw()
 spr(self.tile,self.pos.x,self.pos.y)
end

cls_pwrup_doppelgaenger=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)

function cls_pwrup_doppelgaenger:act_on_player(player)
 for i=0,3 do
  local spawn=room:spawn_player(player.input_port)
  spawn.is_doppelgaenger=true
 end
end


pwrups={ cls_pwrup_doppelgaenger }
tiles[spr_power_up]=cls_pwrup_dropper
