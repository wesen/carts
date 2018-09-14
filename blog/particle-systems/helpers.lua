function angle2vec(a)
 return cos(a),sin(a)
end

function rndangle(a)
 return angle2vec(rnd(a or 1))
end

function copy_table(a)
 local res={}
 for k,v in pairs(a) do
  res[k]=v
 end
 return res
end
