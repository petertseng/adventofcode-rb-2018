require_relative 'lib/priority_queue'

module Nanobot refine Array do
  def dist(pt)
    pt.zip(self).sum { |x, y| (x - y).abs }
  end

  def cover?(pt)
    *pos, r = self
    pos.dist(pt) <= r
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

class Box
  attr_reader :min, :max, :min_idx, :max_idx, :size, :point

  # min, max, min_idx, max_idx are all inclusive.
  def initialize(min, max, min_idx, max_idx)
    @min = min.freeze
    @max = max.freeze
    @min_idx = min_idx.freeze
    @max_idx = max_idx.freeze
    @sizes = max_idx.zip(min_idx).map { |maxi, mini| maxi - mini + 1 }.freeze
    # Just an estimate is fine.
    @size = @sizes.reduce(1, :*)
    @point = min.zip(max).all? { |a, b| a == b } ? min.to3d : nil
  end

  def touched_by?(bot)
    bot.zip(@min, @max).all? { |(bmin, bmax), min, max|
      bmin <= max && min <= bmax
    }
  end

  def contained_by?(bot)
    bot.zip(@min, @max).all? { |(bmin, bmax), min, max|
      bmin <= min && min <= bmax && bmin <= max && max <= bmax
    }
  end

  def min_dist
    return point.sum(&:abs) if point

    # This ignores the fact that there might be no 3D solution.
    # However, this is fine since we'll discover this fact later on.
    @min.zip(@max).map { |min, max|
      # Opposite signs implies zero.
      # Otherwise, the minimum absolute value (min if positive, max if negative)
      min * max <= 0 ? 0 : min > 0 ? min : -max
      # I beleve it's correct to take the max of the individual dimensions.
      # Consider the 2d case:
      # One interval may contain zero, but the other be very far away.
      # In tha case, the minimum distance isn't zero, it's decided by the other one.
    }.max
  end

  def split(coords)
    size, largest_dimension = @sizes.each_with_index.max_by(&:first)

    if size == 1
      # Split into all points that have 3D equivalents.
      ranges = @min.zip(@max).map { |min, max|
        # Given that the intersecting region is bounded on each side by *some* bot's interval,
        # and all this region's limits correspond to some bot's interval,
        # I think it is always safe to only take [min, min+1, max-1, max]
        # (+/- 1 due to needing to make sure parity matches up)
        #
        # However, just to be safe, we'll impose an arbitrary limit,
        # and below the limit we'll just exhaustively check all possibilities.
        # Arbitrarily choosing 20 because even if all four dimensions have 20,
        # 160k will hopefully not be too bad.
        #
        # Note that the limit gets exceeded by the adversarial input,
        # since the final region we split is
        # [[-499998, 500001], [-499998, 500001], [-499998, 500001], [500000, 500001]]
        #
        # TODO: Three of the dimensions determine the fourth (a+d = b+c)
        # otherwise there is no solution in 3D.
        # Could take advantage of this to narrow down the possibilities.
        max - min < 20 ? (min..max).to_a : [min, min + 1, max - 1, max]
      }
      valids = ranges[0].product(*ranges[1..-1]).select(&:to3d)
      return valids.map { |pt| self.class.new(pt, pt, [], []) }
    end

    coord = coords[largest_dimension]

    min, max = @min_idx[largest_dimension], @max_idx[largest_dimension]
    mid = (min + max) / 2

    [
      self.class.new(
        @min,
        (m = @max.dup; m[largest_dimension] = coord[mid]; m),
        @min_idx,
        (m = @max_idx.dup; m[largest_dimension] = mid; m),
      ),
      self.class.new(
        # Notice how we have to use a value that's not necessarily in coord
        # (coord[mid] + 1 rather than coord[mid + 1])
        # If the interval starts at an even number, but the solution needs an odd number,
        # we can't skip ahead to coord[mid + 1] safely.
        # See the 85761543 input for an example.
        # We can get around this by including +/- 1 in coord,
        # but that means each bot generates 6 partition points instead of 2,
        # which is not worth it.
        (m = @min.dup; m[largest_dimension] = coord[mid] + 1; m),
        @max,
        (m = @min_idx.dup; m[largest_dimension] = mid + 1; m),
        @max_idx,
      ),
    ]
  end

  def to_s
    @min.zip(@max).map { |min, max| min == max ? min : Range.new(min, max) }.to_s
  end
end

surround = ARGV.delete('--surround')
verbose = ARGV.delete('-v')

bots = ARGF.map { |l|
  l.scan(/-?\d+/).map(&:to_i).freeze
}.freeze

best_bot = bots.max_by(&:last)
puts "best bot #{best_bot}" if verbose
puts bots.count { |*bot, _| best_bot.cover?(bot) }

# Part 2:
# Use 4D coordinates.
# In this way, we need only partition where intervals begin/end.
# Thus, for N bots, for each dimension we only have 2N partition points.
# https://old.reddit.com/r/adventofcode/comments/a9co1u/day_23_part_2_adversarial_input_for_recursive/ecmpxad/
#
# In 3D space, we do not have this capability,
# because bot regions are octahedral.
# We instead have to partition the space in half each time.
#
# Lower bound: Number of bots that fully contain a region
# Upper bound: Number of bots that touch a region
#
# We explore areas with the best upper bounds.
# When we explore a point (or a region where lower == upper),
# we know the exact number of intersections there.

def coords(bots)
  [0, 1, 2, 3].map { |i| bots.flat_map { |b| b[i] }.uniq.sort }
end

def most_intersected(bots, verbose: false)
  # Start w/ something covering all bots.
  coords = coords(bots)
  start = Box.new(coords.map(&:min), coords.map(&:max), [0] * 4, coords.map { |c| c.size - 1 })

  puts "start w/ #{start}" if verbose

  dequeues = 0

  pq = PriorityQueue.new
  # We need to order by [max upper bound, min dist]
  # This allows us to terminate when we dequeue a point,
  # since nothing can have a better upper bound nor be closer to the origin.
  #
  # Supposedly, adding size to the ordering speeds things up,
  # but I did not observe any such effect.
  #
  # I was NOT convinced that adding -lower_bound to the ordering improves anything.
  pq[start] = [-bots.size, start.min_dist, start.size]

  while (region, (neg_upper_bound, _) = pq.pop(with_priority: true))
    dequeues += 1
    outer_upper_bound = -neg_upper_bound

    if region.point
      puts "dequeued #{region} w/ #{outer_upper_bound} bots, after #{dequeues} dequeues" if verbose
      return region
    end

    region.split(coords).each { |split|
      #lower_bound = bots.count { |b| split.contained_by?(b) }
      upper_bound = bots.count { |b| split.touched_by?(b) }
      pq[split.freeze] = [-upper_bound, split.min_dist, split.size]
    }
  end
end

best_region = most_intersected(bots.map(&:aabb), verbose: verbose)
best_point = best_region.point
best_count = bots.count { |bot| bot.cover?(best_point) }

puts "#{best_count} @ #{best_point}" if verbose
puts best_point.sum(&:abs)

(-3..3).to_a.repeated_permutation(3) { |delta|
  new_pt = best_point.zip(delta).map(&:sum)
  count_here = bots.count { |bot| bot.cover?(new_pt) }
  puts "#{new_pt}: #{count_here}#{' WINNER!' if count_here >= best_count}"
} if surround
