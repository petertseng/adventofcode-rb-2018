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

verbose = ARGV.delete('-v')

bots = ARGF.map { |l|
  l.scan(/-?\d+/).map(&:to_i).freeze
}.freeze

best_bot = bots.max_by(&:last)
puts "best bot #{best_bot}" if verbose
puts bots.count { |*bot, _| best_bot.cover?(bot) }

# Part 2:
# Flatten into 1d.
# https://www.reddit.com/r/adventofcode/comments/a8s17l/2018_day_23_solutions/ecdqzdg/
# Hilariously and obviously incorrect,
# but a correct answer on many inputs, by construction of inputs.
# (However, on the 89915526 input, gets 89915524 instead)
#
# Note that this solution isn't really capable of saying where the point is.

endpoints = bots.flat_map { |*bot, r|
  d = bot.sum(&:abs)
  [
    [[0, d - r].max, 1],
    [d + r + 1, -1],
  ]
}.sort_by(&:first)

count = 0
max_count = 0
result = 0

endpoints.each { |dist, polarity|
  count += polarity
  if count > max_count
    max_count = count
    result = dist
  end
}

puts "#{max_count} @ [unknown]" if verbose
puts result
