spr_mine=69

cls_mine=subclass(cls_interactable,function(self,pos)
 cls_interactable._ctr(self,pos.x,pos.y,0,6,8,2)
 self.spr=spr_mine
end)

function cls_mine:on_player_collision(player)
 make_blast(self.x,self.y,30)
 del(interactables,self)
end
tiles[spr_mine]=cls_mine

cls_suicide_bomb=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)

function cls_suicide_bomb:on_powerup_stop(player)
 if (player.power_up_countdown<=0) make_blast(player.x,player.y,30)
end

spr_suicide_bomb=45
powerup_colors[spr_suicide_bomb]=8
powerup_countdowns[spr_suicide_bomb]=5
tiles[spr_suicide_bomb]=cls_suicide_bomb
