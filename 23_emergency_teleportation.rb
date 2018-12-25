require 'set'

module Nanobot refine Array do
  def dist(pt)
    pt.zip(self).sum { |x, y| (x - y).abs }
  end

  def cover?(pt)
    *pos, r = self
    pos.dist(pt) <= r
  end

  # Intervals is [[xmin, xmax], [ymin, ymax], [zmin, zmax]]
  def &(intervals)
    zip(intervals).map { |(mina, maxa), (minb, maxb)|
      return nil if minb > maxa || mina > maxb
      [[mina, minb].max, [maxa, maxb].min]
    }
  end

  def to4d
    x, y, z = self
    [x + y + z, x - y + z, x + y - z, x - y - z]
  end

  def to3d
    # x+y+z = a
    # x-y+z = b
    # x+y-z = c
    # x-y-z = d
    #
    # x = (a + d) / 2
    # y = (c - d) / 2
    # z = (a - c) / 2
    #
    # (and a+d = b+c)
    a, b, c, d = self
    return nil if (a + d).odd?
    x = (a + d) / 2
    return nil if (c - d).odd?
    y = (c - d) / 2
    return nil if (a - c).odd?
    z = (a - c) / 2
    return nil if x - y + z != b
    [x, y, z]
  end

  # axis-aligned bounding box
  def aabb
    *pos, r = self
    mins  = pos.to4d.map { |c| c - r }
    maxes = pos.to4d.map { |c| c + r }
    mins.zip(maxes)
  end
end end

using Nanobot

surround = ARGV.delete('--surround')
verbose = ARGV.delete('-v')

bots = ARGF.map { |l|
  l.scan(/-?\d+/).map(&:to_i).freeze
}.freeze

best_bot = bots.max_by(&:last)
puts "best bot #{best_bot}" if verbose
puts bots.count { |*bot, _| best_bot.cover?(bot) }

# Part 2:
# Clique
# Graph where an edge means "ranges overlap"
#
# Note that being a clique is not SUFFICIENT to show they have a mutual overlap,
# (counterexample [0, 0, 1], [0, 1, 0], [1, 0, 0], [1, 1, 1])
# but it is of course NECESSARY.
#
# So, we find cliques and check whether they actually overlap,
# using 4d axis-aligned bounding boxes.

# O(n^2) overlap check
overlap = Array.new(bots.size) { Set.new }
bots.each_index { |i|
  *bot1, r1 = bots[i]
  ((i + 1)...bots.size).each { |j|
    *bot2, r2 = bots[j]
    next if bot1.dist(bot2) > r1 + r2
    overlap[i] << j
    overlap[j] << i
  }
}
p overlap if verbose && bots.size < 100

def max_clique(neighbours)
  bests = []

  bk = ->(r, p, x) {
    if p.empty? && x.empty?
      bests << r.freeze
      return
    end

    # pivot on highest degree
    u = (p | x).max_by { |c| neighbours[c].size }
    p2 = p.dup
    x2 = x.dup
    (p - neighbours[u]).each { |v|
      bk[r + [v], p2 & neighbours[v], x2 & neighbours[v]]
      p2 -= [v]
      x2 << v
    }
  }

  bk[Set.new, Set.new([*0...neighbours.size]), Set.new]
  bests
end

def common_area(bots)
  area = [[-1.0 / 0.0, 1.0 / 0.0]] * 4
  bots.each { |bot|
    return nil unless area &= bot.aabb
  }
  area
end

def range_to_3d(area)
  r0, *rs = area.map { |min, max|
    # Arbitrary limit, but sometimes we'd hit a "too big to product"...
    # I'm not sure whether only taking the endpoints is sound or not.
    max - min < 100 ? Range.new(min, max).to_a : [min, max]
  }
  r0.product(*rs).map(&:to3d).compact
end

sizes = ->(cliques) { cliques.map(&:size).group_by(&:itself).transform_values(&:size).sort_by { |k, _| -k } }

cliques = max_clique(overlap)
puts "#{cliques.size} cliques with sizes #{sizes[cliques]}" if verbose

best_count = 0
best_points = []
actually_intersect = 0

# Find the largest ones that actually intersect.
cliques.sort_by(&:size).reverse_each { |clique|
  break if best_count > clique.size

  if (area = common_area(clique.map { |i| bots[i] }))
    best_points.concat(range_to_3d(area))
  end

  good_size = clique.size

  while best_points.empty?
    # clique didn't actually intersect at any 3d point...
    # try to shrink it until it does.
    good_size -= 1
    break if best_count > good_size

    clique.to_a.combination(good_size) { |subclique|
      next unless (area = common_area(subclique.map { |i| bots[i] }))
      best_points.concat(range_to_3d(area))
    }
  end

  next if best_points.empty?

  actually_intersect += 1
  best_count = good_size
}

if verbose
  puts "#{actually_intersect} clique(s) of size #{best_count} intersect at #{best_points.size} points"
  p best_points if best_points.size < 100
end

best_point = best_points.min_by { |pt| pt.sum(&:abs) }

puts "#{best_count} @ #{best_point}" if verbose
puts best_point.sum(&:abs)

(-3..3).to_a.repeated_permutation(3) { |delta|
  new_pt = best_point.zip(delta).map(&:sum)
  count_here = bots.count { |bot| bot.cover?(new_pt) }
  puts "#{new_pt}: #{count_here}#{' WINNER!' if count_here >= best_count}"
} if surround
