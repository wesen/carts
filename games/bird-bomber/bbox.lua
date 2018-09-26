function do_bboxes_collide(a,b)
 return a.bbx > b.aax and
  a.bby > b.aay and
  a.aax < b.bbx and
  a.aay < b.bby
end

function do_bboxes_collide_offset(a,b,dx,dy)
 return (a.bbx+dx) > b.aax and
   (a.bby+dy) > b.aay and
   (a.aax+dx) < b.bbx and
   (a.aay+dy) < b.bby
end
