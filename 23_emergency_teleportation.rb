module Nanobot refine Array do
  def dist(pt)
    pt.zip(self).sum { |x, y| (x - y).abs }
  end

  def cover?(pt)
    *pos, r = self
    pos.dist(pt) <= r
  end

  def scale_down(n)
    *pos, r = self
    # Add an extra 1 to the radius to allow for some errors.
    pos.map { |x| x.to_f / n } << (r.to_f / n).ceil + 1
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
# Scale down, find best points in the scaled down version.
# Scale back up.

def coords(bots)
  [0, 1, 2, 3].map { |i| bots.flat_map { |b| b[i] }.uniq.sort }
end

# Find the max coordinate and use that as scale.
scale = 1 << bots.flatten.map(&:abs).max.to_s(2).size
scaled_bots = bots.map { |b| b.scale_down(scale) }

coords = coords(scaled_bots)
ranges = coords.map(&:minmax).map { |min, max| min.floor..max.ceil }
p ranges if verbose

best_pts = []
best_count = 0

# Initial points
ranges[0].to_a.product(*ranges[1..2].map(&:to_a)) { |pt|
  count = scaled_bots.count { |bot| bot.cover?(pt) }
  if count > best_count
    best_count = count
    best_pts = [pt]
  elsif count == best_count
    best_pts << pt
  end
}

while scale > 1
  puts "#{scale}: #{best_pts} (#{best_pts.size}) #{best_count}" if verbose

  scale /= 2
  scaled_bots = scale == 1 ? bots : bots.map { |b| b.scale_down(scale) }
  best_pts.each { |best_pt| best_pt.map! { |x| x * 2 } }

  best_count = 0
  new_best_pts = []

  seen = {}

  # You'd think that only 0 and 1 are necessary,
  # but it looks like we need to account for some error again.
  d = [-2, -1, 0, 1, 2]
  d.product(d, d).each { |delta|
    best_pts.each { |best_pt|
      pt = best_pt.zip(delta).map(&:sum)
      next if seen[pt]
      seen[pt] = true

      count = scaled_bots.count { |bot| bot.cover?(pt) }
      if count > best_count
        best_count = count
        new_best_pts = [pt]
      elsif count == best_count
        new_best_pts << pt
      end
    }
  }

  best_pts = new_best_pts.uniq
end

puts "#{scale}: #{best_pts} (#{best_pts.size}) #{best_count}" if verbose

best_point = best_pts.min_by { |pt| pt.sum(&:abs) }
if verbose
  best_dist = best_point.sum(&:abs)
  # In case there's more than one, show them all.
  others = best_pts.select { |pt| pt != best_point && pt.sum(&:abs) == best_dist }
  p others unless others.empty?
end

puts "#{best_count} @ #{best_point}" if verbose
puts best_point.sum(&:abs)

(-3..3).to_a.repeated_permutation(3) { |delta|
  new_pt = best_point.zip(delta).map(&:sum)
  count_here = bots.count { |bot| bot.cover?(new_pt) }
  puts "#{new_pt}: #{count_here}#{' WINNER!' if count_here >= best_count}"
} if surround
