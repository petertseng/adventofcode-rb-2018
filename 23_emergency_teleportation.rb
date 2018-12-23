module Nanobot refine Array do
  def dist(pt)
    pt.zip(self).sum { |x, y| (x - y).abs }
  end

  def cover?(pt)
    *pos, r = self
    pos.dist(pt) <= r
  end
end end

surround = ARGV.delete('--surround')
verbose = ARGV.delete('-v')

bots = ARGF.map { |l|
  l.scan(/-?\d+/).map(&:to_i).freeze
}.freeze

using Nanobot

best_bot = bots.max_by(&:last)
puts "best bot #{best_bot}" if verbose
puts bots.count { |*bot, _| best_bot.cover?(bot) }

# WRONG: Part 2:
# Start with a mean point then just guess points closer and closer to the origin
# Demonstrably wrong!!!
# Found a local maximum that happened to be at same distance as the real maximum.
# Thus, I got the right answer for the completely wrong reason.

def coords(bots)
  [0, 1, 2].map { |i| bots.map { |b| b[i] } }
end

coords = coords(bots)
best_point = coords.map { |c| c.sum / bots.size }
best_count = bots.count { |bot| bot.cover?(best_point) }

currx, curry, currz = best_point

is_good = ->(pt) {
  in_range_here = bots.count { |bot| bot.cover?(pt) }
  best_count = in_range_here if in_range_here > best_count
  in_range_here == best_count
}

stepit = ->(step) {
  # Not even gradient descent (pick the best direction to go)!
  # Instead, just blindly moves closer to origin as long as it's not worse!
  [
    [1, 1, 1],
    [1, 1, 0],
    [1, 0, 1],
    [0, 1, 1],
    [1, 0, 0],
    [0, 1, 0],
    [0, 0, 1],
  ].each { |x, y, z|
    xdir = (currx > 0 ? -step : step) * x
    ydir = (curry > 0 ? -step : step) * y
    zdir = (currz > 0 ? -step : step) * z
    while is_good[[currx + xdir, curry + ydir, currz + zdir]]
      currx += xdir
      curry += ydir
      currz += zdir
    end
  }
}

max_step = 1 << bots.flatten.max.to_s(2).size
puts "Step size #{max_step}" if verbose

best_point = 0.step { |t|
  puts "Try #{t}: #{best_count} bots @ #{[currx, curry, currz]}" if verbose
  step = max_step
  best_before_stepping = best_count
  while step > 0
    stepit[step]
    step /= 2
  end
  break [currx, curry, currz] if best_count == best_before_stepping
}

puts "#{best_count} @ #{best_point}" if verbose
puts best_point.sum(&:abs)

(-3..3).to_a.repeated_permutation(3) { |delta|
  new_pt = best_point.zip(delta).map(&:sum)
  count_here = bots.count { |bot| bot.cover?(new_pt) }
  puts "#{new_pt}: #{count_here}#{' WINNER!' if count_here >= best_count}"
} if surround
