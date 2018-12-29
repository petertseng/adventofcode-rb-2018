require_relative 'lib/union_find'

points = ARGF.map { |l| l.scan(/-?\d+/).map(&:to_i) }.freeze

uf = UnionFind.new(points)

# While a plain old points.combination(2) will work,
# let's do slightly better.
# We only need to check points whose first coordinate differ by <= 3.
# Cuts runtime in roughly half.
# Taking it further, we can filter by the second coordinate as well,
# cutting runtime by half again!
# (Filtering by a third coordinate unfortunately does not help)
points = points.group_by { |i| i.take(2).freeze }.each_value(&:freeze).freeze

points.each { |(c1, c2), pts|
  (0..3).each { |delta1|
    # Note that the first coordinate could look in only one direction,
    # but this second one needs to look in both.
    # Otherwise, we could miss points along the other diagonal.
    d2limit = 3 - delta1
    (-d2limit..d2limit).each { |delta2|
      pts.product(points[[c1 + delta1, c2 + delta2]] || []) { |pt1, pt2|
        uf.union(pt1, pt2) if pt1.zip(pt2).sum { |x, y| (x - y).abs } <= 3
      }
    }
  }
}

puts uf.num_sets
