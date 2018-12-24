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

def range_to_3d(area)
  r0, *rs = area.map { |min, max|
    # Arbitrary limit, but sometimes we'd hit a "too big to product"...
    # I'm not sure whether only taking the endpoints is sound or not.
    max - min < 100 ? Range.new(min, max).to_a : [min, max]
  }
  r0.product(*rs).map(&:to3d).compact
end

stack = [
  bots.map.with_index { |bot, i| [bot.aabb, Set.new([i])] }.sort_by { |bounds, _|
    mins, maxes = bounds.transpose
    [mins, maxes.map(&:-@)]
  }
]

best_count = 0
bests = nil

while (rest = stack[-1])
  if rest.sum(Set.new, &:last).size < best_count
    stack.pop
    next
  end

  octa, n = rest.pop
  sub = Hash.new { |h, k| h[k] = Set.new }

  rest.each { |octa2, m|
    next unless (octa3 = octa & octa2)
    if octa == octa3
      n |= m
    else
      sub[octa3] |= m
    end
  }

  if n.size > best_count
    best_count = n.size
    bests = [octa.freeze]
  elsif n.size == best_count
    bests << octa.freeze
  end

  stack << sub.sort_by { |bounds, _|
    mins, maxes = bounds.transpose
    [mins, maxes.map(&:-@)]
  }.map { |k, v| [k, v | n] }
end

best_points = bests.flat_map { |b| range_to_3d(b) }
best_point = best_points.min_by { |pt| pt.sum(&:abs) }

puts "#{best_count} @ #{best_point}" if verbose
puts best_point.sum(&:abs)

(-3..3).to_a.repeated_permutation(3) { |delta|
  new_pt = best_point.zip(delta).map(&:sum)
  count_here = bots.count { |bot| bot.cover?(new_pt) }
  puts "#{new_pt}: #{count_here}#{' WINNER!' if count_here >= best_count}"
} if surround
