require_relative 'lib/priority_queue'

def closest_1d(target, low, high)
  return 0 if low <= target && target <= high
  target > high ? target - high : low - target
end

def farthest_1d(target, low, high)
  return [target - low, high - target].max if low <= target && target <= high
  target > high ? target - low : high - target
end

module Nanobot refine Array do
  def dist(pt)
    pt.zip(self).sum { |x, y| (x - y).abs }
  end

  def cover?(pt)
    *pos, r = self
    pos.dist(pt) <= r
  end
end end

using Nanobot

class Box
  attr_reader :min, :max

  # min/max are both [x, y, z], inclusive
  def initialize(min, max)
    @min = min.freeze
    @max = max.freeze
  end

  def empty?
    @min.zip(@max).any? { |min, max| min > max }
  end

  def point?
    @min.zip(@max).all? { |min, max| min == max }
  end

  def touched_by?(bot)
    *pos, r = bot
    pos.zip(@min, @max).sum { |args| closest_1d(*args) } <= r
  end

  def contained_by?(bot)
    *pos, r = bot
    pos.zip(@min, @max).sum { |args| farthest_1d(*args) } <= r
  end

  def size
    @min.zip(@max).reduce(1) { |acc, (min, max)|
      dim = min > max ? 0 : (max - min + 1)
      acc * dim
    }
  end

  def min_dist
    @min.zip(@max).sum { |min, max| closest_1d(0, min, max) }
  end

  def split
    mid = @min.zip(@max).map { |min, max| (min + max) / 2 }

    8.times.map { |bits|
      newmin = [
        bits & 1 == 0 ? @min[0] : mid[0] + 1,
        bits & 2 == 0 ? @min[1] : mid[1] + 1,
        bits & 4 == 0 ? @min[2] : mid[2] + 1,
      ]
      newmax = [
        bits & 1 == 0 ? mid[0] : @max[0],
        bits & 2 == 0 ? mid[1] : @max[1],
        bits & 4 == 0 ? mid[2] : @max[2],
      ]
      self.class.new(newmin, newmax)
    }.reject(&:empty?)
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
# Split the search region into octants,
# dividing a large cube into eight smaller ones.
#
# Lower bound: Number of bots that fully contain a region
# Upper bound: Number of bots that touch a region
#
# We explore areas with the best upper bounds.
# When we explore a point (or a region where lower == upper),
# we know the exact number of intersections there.

def coords(bots)
  [0, 1, 2].map { |i| bots.map { |b| b[i] } }
end

def most_intersected(bots, verbose: false)
  # Start w/ something covering all bots.
  coords = coords(bots)
  start = Box.new(coords.map(&:min), coords.map(&:max))

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

    if region.point?
      puts "dequeued #{region} w/ #{outer_upper_bound} bots, after #{dequeues} dequeues" if verbose
      return region
    end

    region.split.each { |split|
      #lower_bound = bots.count { |b| split.contained_by?(b) }
      upper_bound = bots.count { |b| split.touched_by?(b) }
      pq[split.freeze] = [-upper_bound, split.min_dist, split.size]
    }
  end
end

best_region = most_intersected(bots, verbose: verbose)
best_point = best_region.min.zip(best_region.max).map { |min, max| closest_1d(0, min, max) }
best_count = bots.count { |bot| bot.cover?(best_point) }

puts "#{best_count} @ #{best_point}" if verbose
puts best_point.sum(&:abs)

(-3..3).to_a.repeated_permutation(3) { |delta|
  new_pt = best_point.zip(delta).map(&:sum)
  count_here = bots.count { |bot| bot.cover?(new_pt) }
  puts "#{new_pt}: #{count_here}#{' WINNER!' if count_here >= best_count}"
} if surround
