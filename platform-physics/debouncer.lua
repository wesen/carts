cls_debouncer=class(function(self,duration)
 self.duration=duration
 self.t=0
end)

function cls_debouncer:debounce(v)
 if v then
  self.t=self.duration
 elseif self.t>0 then
  self.t-=1
 end
end

function cls_debouncer:is_on()
 return self.t>0
end
