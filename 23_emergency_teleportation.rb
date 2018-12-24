require_relative 'lib/priority_queue'

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

def common_area(bots)
  area = [[-1.0 / 0.0, 1.0 / 0.0]] * 4
  bots.each { |bot|
    return nil unless area &= bot.aabb
  }
  area
end

def range_to_3d(area)
  r0, *rs = area.map { |r| Range.new(*r).to_a }
  r0.product(*rs).map(&:to3d).compact
end

# Count how many intersections each bot has with all others,
# in O(n^2) time.
intersect_counts = bots.map { |*bot1, r1|
  bots.count { |*bot2, r2| bot1.dist(bot2) <= r1 + r2 }
}

# If we aim to find a point in range of N bots,
# there must be at least N bots with intersect count >= N.
intersect_freqs = intersect_counts.group_by(&:itself).transform_values(&:size)
intersect_freqs.sort_by(&:first).reverse_each { |k, v| puts "#{k}: #{v}" } if verbose

best_count = nil
bots_with_at_least = 0
best_point = bots.size.downto(1) { |group_size|
  bots_with_at_least += intersect_freqs[group_size] || 0
  next if bots_with_at_least < group_size

  # This group size is eligible!

  best_count = group_size

  eligible_bots = bots.zip(intersect_counts).select { |bot, count|
    count >= group_size
  }.map(&:first)

  found = []

  eligible_bots.combination(group_size) { |used_bots|
    next unless (area = common_area(used_bots))
    found.concat(pts = range_to_3d(area))
    puts "#{group_size} bots at #{area} - #{pts.size} points" if verbose
  }

  next if found.empty?

  p found if verbose
  break found.min_by { |pt| pt.sum(&:abs) }
}

puts "#{best_count} @ #{best_point}" if verbose
puts best_point.sum(&:abs)

(-3..3).to_a.repeated_permutation(3) { |delta|
  new_pt = best_point.zip(delta).map(&:sum)
  count_here = bots.count { |bot| bot.cover?(new_pt) }
  puts "#{new_pt}: #{count_here}#{' WINNER!' if count_here >= best_count}"
} if surround
