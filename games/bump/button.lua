cls_button=class(typ_button,function(self,btn_nr,input_port)
 self.btn_nr=btn_nr
 self.input_port=input_port
 self.is_down=false
 self.is_pressed=false
 self.down_duration=0
 self.hold_time=0
 self.ticks_down=0
end)

function cls_button:update()
 self.is_pressed=false
 if btn(self.btn_nr, self.input_port) then
  self.is_pressed=not self.is_down
  self.is_down=true
  self.ticks_down+=1
 else
  self.is_down=false
  self.ticks_down=0
  self.hold_time=0
 end
end

function cls_button:was_recently_pressed()
 return self.ticks_down<jump_button_grace_interval and self.hold_time==0
end

function cls_button:was_just_pressed()
 return self.is_pressed
end

function cls_button:is_held()
 return self.hold_time>0 and self.hold_time<jump_max_hold_time
end