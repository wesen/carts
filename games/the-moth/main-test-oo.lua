cls_parent=class(0,function(self)
 self.foobar=1
end)

function cls_parent:print()
 print(self.foobar)
end

cls_child=subclass(1,cls_parent,function(self)
 cls_parent._ctr(self)
 self.foobar=3
end)

cls_grandchild=subclass(2,cls_child,function(self)
 cls_child._ctr(self)
 self.foobar=4
end)

a=cls_parent.init()
a:print()
b=cls_child.init()
b:print()
c=cls_grandchild.init()
c:print()