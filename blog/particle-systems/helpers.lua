function angle2vec(a)
 return cos(a),sin(a)
end

function rndangle(a)
 return angle2vec(rnd(a or 1))
end
