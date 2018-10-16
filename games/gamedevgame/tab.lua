cls_tab=class(function(self, name)
 self.name=name
end)

function cls_tab:draw()
end

function cls_tab:update()
end

cls_money_tab=subclass(cls_tab,function(self,name)
 cls_tab._ctr(self,name)
end)

function cls_money_tab:draw()
 cls_tab.draw(self)
end

tab_game=cls_tab.init("gamedev")
tab_money=cls_tab.init("studio")
tab_release=cls_tab.init("release")

glb_resource_manager.tabs={tab_game,tab_money,tab_release}
glb_current_tab=tab_game
