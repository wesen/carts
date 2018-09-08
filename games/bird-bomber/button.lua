cls_button=class(function(self,btn_nr,max_hold_time)
 self.btn_nr=btn_nr
 self.is_down=false
 self.is_pressed=false
 self.down_duration=0
 self.hold_time=0
 self.ticks_down=0
 self.max_hold_time=max_hold_time
end)

function cls_button:update()
 self.is_pressed=false
 if btn(self.btn_nr) then
  self.is_pressed=not self.is_down
  self.is_down=true
  self.ticks_down+=1
 else
  self.is_down=false
  self.ticks_down=0
  self.hold_time=0
 end
end

function cls_button:was_just_pressed()
 return self.is_pressed
end

function cls_button:is_held()
 return self.hold_time>0 and self.hold_time<self.max_hold_time
end
