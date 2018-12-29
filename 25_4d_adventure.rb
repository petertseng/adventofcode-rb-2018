require_relative 'lib/union_find'

points = ARGF.map { |l| l.scan(/-?\d+/).map(&:to_i) }.freeze

uf = UnionFind.new(points)

# While a plain old points.combination(2) will work,
# let's do slightly better.
# We only need to check points whose first coordinate differ by <= 3.
# Cuts runtime in roughly half.
points = points.group_by(&:first).each_value(&:freeze).freeze

points.each { |c1, pts|
  (0..3).each { |delta|
    pts.product(points[c1 + delta] || []) { |pt1, pt2|
      uf.union(pt1, pt2) if pt1.zip(pt2).sum { |x, y| (x - y).abs } <= 3
    }
  }
}

puts uf.num_sets
