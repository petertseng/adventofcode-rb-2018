require_relative 'lib/union_find'

input = ARGF.each_line.map { |l| l.scan(/-?\d+/).map(&:to_i) }

uf = UnionFind.new(input)

# While a plain old input.combination(2) will work,
# let's do slightly better.
# We only need to check points whose first coordinate differ by <= 3.
# Cuts runtime in roughly half.
input = input.group_by(&:first)

input.each { |c1, pts|
  (0..3).each { |delta|
    pts.product(input[c1 + delta] || []) { |pt1, pt2|
      uf.union(pt1, pt2) if pt1.zip(pt2).sum { |x, y| (x - y).abs } <= 3
    }
  }
}

puts uf.num_sets
