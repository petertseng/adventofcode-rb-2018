require_relative 'lib/union_find'

points = ARGF.map { |l| l.scan(/-?\d+/).map(&:to_i) }.freeze

uf = UnionFind.new(points)

points.combination(2) { |pt1, pt2|
  uf.union(pt1, pt2) if pt1.zip(pt2).sum { |x, y| (x - y).abs } <= 3
}

puts uf.num_sets
