require_relative 'lib/priority_queue'

module Nanobot refine Array do
  def radius
    last
  end

  def cover?(pt)
    *pos, r = self
    pos.dist(pt) <= r
  end

  def dist(pt)
    pt.zip(self).sum { |x, y| (x - y).abs }
  end

  def each_corner
    x, y, z, r = self
    yield(x + r, y, z)
    yield(x - r, y, z)
    yield(x, y + r, z)
    yield(x, y - r, z)
    yield(x, y, z + r)
    yield(x, y, z - r)
  end

  def dominates?(region)
    r = last
    # Would use #all?, but efficiency (don't want to create an array of corners)
    region.each_corner { |*corner| return false unless dist(corner) <= r }
    true
  end

  def out?(region)
    my_r = last
    *pos, r = region
    dist(pos) > my_r + r
  end

  def score
    *pos, r = self
    [0, pos.sum(&:abs) - r].max
  end

  def split
    x, y, z, r = self
    mov = (r.to_f / 3).ceil
    new_r = r - mov

    splits = [
      [x - mov, y, z, new_r],
      [x, y - mov, z, new_r],
      [x, y, z - mov, new_r],
      [x + mov, y, z, new_r],
      [x, y + mov, z, new_r],
      [x, y, z + mov, new_r],
    ]

    splits << [x, y, z, 0] if r == 1

    splits
  end
end end

using Nanobot

surround = ARGV.delete('--surround')
thorough = ARGV.delete('--thorough')
verbose = ARGV.delete('-v')

bots = ARGF.map { |l|
  l.scan(/-?\d+/).map(&:to_i).freeze
}.freeze

best_bot = bots.max_by(&:last)
puts "best bot #{best_bot}" if verbose
puts bots.count { |*bot, _| best_bot.cover?(bot) }

# Part 2:
# Split the search region into octahedra,
# dividing a large one into six smaller ones.
#
# Lower bound: Number of bots that fully contain a region
# Upper bound: Number of bots that touch a region
#
# We explore areas with the best upper bounds.
# When we explore a point (or a region where lower == upper),
# we know the exact number of intersections there.

def coords(bots)
  [0, 1, 2].map { |i| bots.flat_map { |b| b[i] }.uniq.sort }
end

# Start with a point in the middle, and cover all bots.
midpoint = coords(bots).map { |c| c.minmax.sum / 2 }
midpoint << 1

uncovered_bots = bots.reject { |b| midpoint.dominates?(b) }

until uncovered_bots.empty?
  # The multiplication factor of 3 is arbitrary
  midpoint[-1] *= 3
  uncovered_bots.reject! { |b| midpoint.dominates?(b) }
end

puts "start w/ #{midpoint}" if verbose

def most_intersected(start, bots, thorough: false, verbose: false)
  dequeues = 0

  seen = {}

  pq = PriorityQueue.new
  pq[start] = thorough ? [-bots.size, start.score, start.radius] : -bots.size

  while (region, (neg_upper_bound, _) = pq.pop(with_priority: true))
    dequeues += 1
    outer_upper_bound = -neg_upper_bound

    if region.radius == 0
      # Not always necessary (usually we terminate in the split section below)
      # but necessary for some radii?
      puts "dequeued #{region} w/ #{outer_upper_bound} bots, after #{dequeues} dequeues" if verbose
      return region
    end

    region.split.each { |split|
      # Unfortunately, the splitting scheme does create some overlap.
      # Thus, it's helpful to reject things we've seen before.
      next if seen[split]
      seen[split] = true

      lower_bound = bots.count { |b| b.dominates?(split) }
      if !thorough && lower_bound == outer_upper_bound
        # SUSPICIOUS termination condition:
        # Shouldn't we continue to search the rest of the area,
        # in case there's a winner closer to the origin???
        # Doesn't this assume there's only one winning point?
        puts "would enqueue #{split} w/ #{lower_bound} bots, after #{dequeues} dequeues" if verbose
        return split
      end

      # SUSPICIOUS SORT:
      # If we want to be sure we found all points,
      # we should sort by [-upper_bound, score, radius]
      # But searching all the closer points takes a long time!
      #
      # Also, attempts to improve perf by adding -lower_bound or radius
      # were not always effective (sometimes even increasing # dequeues)
      # so, I guess we'll stick with just -upper_bound,
      # and avoid creating an extra array???
      upper_bound = bots.count { |b| !b.out?(split) }
      pq[split.freeze] = thorough ? [-upper_bound, split.score, split.radius] : -upper_bound
    }
  end
end

best_region = most_intersected(midpoint, bots, thorough: thorough, verbose: verbose)
best_point = best_region.take(3)
best_count = bots.count { |bot| bot.cover?(best_point) }

puts "#{best_count} @ #{best_point}" if verbose
puts best_point.sum(&:abs)

(-3..3).to_a.repeated_permutation(3) { |delta|
  new_pt = best_point.zip(delta).map(&:sum)
  count_here = bots.count { |bot| bot.cover?(new_pt) }
  puts "#{new_pt}: #{count_here}#{' WINNER!' if count_here >= best_count}"
} if surround
